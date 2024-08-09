
module vectoring_18b (
  input               clk_i,
  input               sob_i,
  input               eob_i,
  input [17:0]        x_i,
  input [17:0]        y_i,
  output logic [17:0] r_o,
  output logic        sob_o,
  output logic        eob_o
);

localparam N = 18;
localparam OUTPUT_REG_EN = 1;
localparam CORDIC_PIPELINE = "even";
localparam TOTAL_DELAY_CORDIC = CORDIC_PIPELINE=="none" ? 0 : (
                                CORDIC_PIPELINE=="all"  ? N : (N/2) );

localparam TOTAL_DELAY = TOTAL_DELAY_CORDIC + OUTPUT_REG_EN;

logic [TOTAL_DELAY-1:0][1:0] flags;

always_ff @( posedge clk_i )
    flags <= { flags[TOTAL_DELAY-2:0], { sob_i, eob_i } };

assign { sob_o, eob_o } = flags[TOTAL_DELAY-1];

vectoring #(
  .N               ( N                              ),
  .DW              ( 18                             ),
  .AW              ( 18                             ),
  .ATAN            ( `include "init/atan_18.vh"     ),
  .KW              ( 18                             ),
  .K               ( 159188                         ),
  .CORDIC_PIPELINE ( CORDIC_PIPELINE                ),
  .OUTPUT_REG_EN   ( OUTPUT_REG_EN                  )
) abs (
  .clk_i           ( clk_i                          ),
  .x_i             ( x_i                            ),
  .y_i             ( y_i                            ),
  .r_o             ( r_o                            ),
  .angle_o         (                                ),
  .quadrant_o      (                                )
);

endmodule
