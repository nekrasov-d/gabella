

module soa #(
  parameter DW  = 18,
  parameter AW  = 11
) (
  input                      clk_i,
  input                      srst_i,
  input                      accumulate_i,
  input                      save_i,
  input [AW:0]               phase_i,
  input [DW-1:0]             freq_gain_i,
  input [11:0]               compression_i,
  output logic signed [15:0] data_o,
  output logic               alarm_o
);

localparam ACC_W = 32;
localparam RANGE = 0;

localparam N = 16;
localparam OUTPUT_REG_EN = 1;
localparam CORDIC_PIPELINE = "even";
localparam TOTAL_DELAY_CORDIC = CORDIC_PIPELINE=="none" ? 0 : (
                                CORDIC_PIPELINE=="all"  ? N : (N/2) );

localparam TOTAL_DELAY = TOTAL_DELAY_CORDIC + OUTPUT_REG_EN;

//******************************************************************

logic        [AW-2:0]     angle_inside_quadrant;
logic        [1:0]        sincos_quadrant;
logic        [15:0]       sincos_angle;
logic        [DW-1:0]     freq_gain_d;
logic                     accumulate_d;
logic                     save_d;
logic        [11:0]       compression_d;
logic signed [15:0]       sin;
logic signed [15:0]       weighted_sin;
logic                     sat_alarm_1;
logic                     sat_alarm_2;


// AW = 11 (0 to pi)
// AW-1 = 10 (0 to pi/2)
// 16 - 10 = 6

assign sincos_quadrant = phase_i[AW:AW-1];
assign sincos_angle[5:0] = 6'b000000;
assign sincos_angle[15:6] = phase_i[AW-2:0];

logic [TOTAL_DELAY-1:0][DW+12+1:0] pipeline;

always_ff @( posedge clk_i )
  pipeline <= { pipeline[TOTAL_DELAY-2:0], { compression_i, accumulate_i, save_i, freq_gain_i } };

assign { compression_d, accumulate_d, save_d, freq_gain_d } = pipeline[TOTAL_DELAY-1];

sincos #(
  .N               ( N                          ),
  .DW              ( 16                         ),
  .AW              ( 16                         ),
  .ATAN            ( `include "init/atan_16.vh" ),
  .KW              ( 16                         ),
  .K               ( 39797                      ),
  .CORDIC_PIPELINE ( CORDIC_PIPELINE            ),
  .OUTPUT_REG_EN   ( OUTPUT_REG_EN              )
) cordic_sincos (
  .clk_i           ( clk_i                      ),
  .quadrant_i      ( sincos_quadrant            ),
  .angle_i         ( sincos_angle               ),
  .sin_o           ( sin                        ),
  .cos_o           (                            )
);

logic signed [16+DW:0] sin_gain_mult  /* synthesis noprune */;
logic signed [16:0]    sin_weighted   /* synthesis noprune */;

assign sin_gain_mult = sin * $signed({ 1'b0, freq_gain_d });
assign sin_weighted  = sin_gain_mult >> DW;

//**********************************************************************************
// Accumulate
//localparam ACC_W = 64;

logic signed [ACC_W-1:0] acc          /* synthesis noprune */;
logic signed [ACC_W  :0] acc_sum      /* synthesis noprune */;
logic signed [ACC_W-1:0] acc_sum_sat  /* synthesis noprune */;
logic signed [ACC_W-1:0] acc_saved    /* synthesis noprune */;
logic        [11:0] compression_saved /* synthesis noprune */;

assign acc_sum = acc + sin_weighted;

sat_sdft #(
  .IW          ( ACC_W+1                     ),
  .OW          ( ACC_W                       )
) sat_1 (
  .x           ( acc_sum                     ),
  .y           ( acc_sum_sat                 ),
  .sat_alarm_o ( sat_alarm_1                 )
);

always_ff @( posedge clk_i )
  if( save_d )
    acc <= '0;
  else
    if( accumulate_d )
      acc <= acc_sum_sat;

always_ff @( posedge clk_i )
  if( save_d )
    begin
      acc_saved         <= acc;
      compression_saved <= compression_d;
    end

//**********************************************************************************
// Apply compression


logic signed [ACC_W+12:0] acc_comp_mult   /* synthesis noprune */;
logic signed [ACC_W:0]    acc_compressed  /* synthesis noprune */;
logic signed [15:0]       produced_sample /* synthesis noprune */;

assign acc_comp_mult  = acc_saved * $signed({ 1'b0, compression_saved } );
assign acc_compressed = acc_comp_mult >> 12;

sat_sdft #(
  .IW          ( ACC_W+1                     ),
  .OW          ( 16                          )
) sat_2 (
  .x           ( acc_compressed              ),
  .y           ( produced_sample             ),
  .sat_alarm_o ( sat_alarm_2                 )
);

always_ff @( posedge clk_i )
  data_o <= produced_sample;

//**********************************************************************************
// Debug section

logic [ACC_W:0] acc_magnitude;
logic [ACC_W:0] acc_magnitude_max;

assign acc_magnitude = `sign(acc_compressed) ? ~acc_saved : acc_saved;

always_ff @( posedge clk_i )
  if( srst_i )
    acc_magnitude_max <= '0;
  else
    if( acc_magnitude > acc_magnitude_max )
      acc_magnitude_max <= acc_magnitude;

assign alarm_o = sat_alarm_1 & sat_alarm_2 & ^acc_magnitude_max;

endmodule
