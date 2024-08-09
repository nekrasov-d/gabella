

module downsampler #(
  parameter DW                   = 16,
  parameter DOWNSAMPLE_FACTOR    = 8, // power of two
  parameter FILTER_TAPS_ROM_FILE = ""
) (
  input                 clk_i,
  input                 srst_i,
  input [DW-1:0]        data_i,
  input                 sample_tick_i,
  input                 side_toggle_i,
  output logic [DW-1:0] data_o,
  output logic          new_sample_tick_o
);

ram_fir #(
  .DW            ( 24                          ),
  .LEN           ( 254                         ),
  .COEFFS_FILE   ( FILTER_TAPS_ROM_FILE        ),
  .RAMSTYLE      ( "M9K"                       )
) fir_filter (
  .clk_i         ( clk_i                       ),
  .srst_i        ( srst_i                      ),
  .sample_valid_i ( sample_tick_i              ),
  .data_i        ( data_i                      ),
  .data_o        ( data_o                      ),
  .data_valid_o  (                             )
);

logic [$clog2(DOWNSAMPLE_FACTOR)-1:0] counter;

always_ff @( posedge clk_i )
  if( srst_i )
    counter <= '0;
  else
    if( sample_tick_i )
       counter <= counter + 1'b1;

assign new_sample_tick_o = sample_tick_i & ( counter == 0 );

endmodule
