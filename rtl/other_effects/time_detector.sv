

module time_detector #(
  parameter TD_MAX_TIME = 100_000, // in samples
  parameter TD_MIN_TIME = 400,
  parameter DW          = $clog2(TD_MAX_TIME)
) (
  input                 clk_i,
  input                 srst_i,
  input                 sample_tick_i,
  input                 trigger_i,
  output logic [DW-1:0] detected_time_o,
  output logic          valid_stb_o
);

logic [DW-1:0] counter;
logic          valid_range;

always_ff @( posedge clk_i )
  if( srst_i || trigger_i )
    counter <= '0;
  else
    counter <= counter + 1'b1;

assign valid_range = ( counter < TD_MAX_TIME ) && ( counter > TD_MIN_TIME );

always_ff @( posedge clk_i )
  if( trigger_i && valid_range )
     detected_time_o <= counter;

always_ff @( posedge clk_i )
  valid_stb_o <= trigger_i && valid_range;

endmodule
