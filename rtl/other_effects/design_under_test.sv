


module design_under_test #(
  parameter DWIDTH = 16
)  (
  input                     clk_i,
  input                     srst_i,
  input                     sample_tick_i,
  input               [2:0] buttons_i,
  input        [DWIDTH-1:0] data_i,
  output logic [DWIDTH-1:0] data_o
);

endmodule
