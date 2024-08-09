

module silence_detector #(
  parameter DW    = 16,
  parameter FLOOR = 300
) (
  input          clk_i,
  input          srst_i,
  input          sample_tick_i,
  input [7:0]    level_i,
  input [DW-1:0] data_i,
  output logic   silence_o
);

localparam THRESHOLD = 10;

localparam WINDOW = 1024; // For 44100 samples/s
localparam COUNTER_BW = $clog2(WINDOW);

logic [DW-2:0] magnitude;

assign magnitude = data_i[DW-1] ? ~data_i[DW-2:0] : data_i[DW-2:0];

logic [DW+COUNTER_BW-1:0] integrator;
logic [COUNTER_BW-1:0]    counter;

logic [DW-2:0] envelope;

logic end_of_window;

assign end_of_window = ( counter == (WINDOW-1) );

always_ff @( posedge clk_i )
  if( srst_i )
    counter <= '0;
  else
    if( sample_tick_i )
      counter <= counter + 1'b1;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    integrator <= end_of_window ? magnitude : integrator + magnitude;

always_ff @( posedge clk_i )
  if( end_of_window )
    envelope <= integrator[ DW-1 + COUNTER_BW - 1 : COUNTER_BW ];


logic [12:0] floor;
assign floor = FLOOR - ( level_i << 4 );

logic silence;
assign silence = ( envelope < floor );

logic [100:0] train;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    train <= { train[99:0], silence };


always_ff @( posedge clk_i )
  if( train == '0 )
    silence_o <= 1'b0;
  else
    if( train == '1 )
      silence_o <= 1'b1;
    else
      silence_o <= silence_o;



endmodule

