
// I specify bitwidth as parameters just to give names to these values.
// Don't edit them

module twiddle_generator_18b #(
  parameter DW          = 18, // Do not edit/override
  parameter AW          = 12, // Do not edit/override
  parameter INTERNAL_AW = 10, // Do not edit/override
  parameter DIRECTION   = "counter clockwise" // or "clockwise"
) (
  input                   clk_i,
  input        [11:0]     index_i,
  output logic [DW*2-1:0] twiddle_o
);

logic signed [DW-1:0] sin;
logic signed [DW-1:0] cos;

logic [1:0]  quadrant;
logic [17:0] angle;

assign quadrant = index_i[11:10];
// 10 --> 16
assign angle    = { index_i[9:0], 8'h00 };

sincos #(
  .N             ( 18                       ),
  .DW            ( 18                       ),
  .AW            ( 18                       ),
  .ATAN          ( `include "init/atan_18.vh"),
  .KW            ( 18                        ),
  .K             ( 159188                     ),
  .REG_EN        ( 1                        )
) cordic_sincos (
  .clk_i         ( clk_i                    ),
  .quadrant_i    ( quadrant                 ),
  .angle_i       ( angle                    ),
  .sin_o         ( sin                      ),
  .cos_o         ( cos                      )
);

generate
  if( DIRECTION=="counter clockwise" )
    begin : counter_clockwise_rotation
      assign twiddle_o = { sin, cos }; // { imag, real }
    end // counter_clockwise_rotation

  else
    begin : clockwise_rotation
      assign twiddle_o = { -sin, cos }; // { imag, real }
    end // clockwise_rotation
endgenerate

endmodule
