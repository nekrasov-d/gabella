/*
 * MIT License
 *
 * Copyright (c) 2024 Dmitriy Nekrasov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * ---------------------------------------------------------------------------------
 *
 * Contaits frequency_control module that transforms the number of the lookup
 * table frequency into increment enable signal which controls sawtooth/cordic.
 * And cordic, which takes sawtooth and prodices sine wave.
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 22:25:44 +0300
*/

module modulation #(
  parameter FREQ_TABLE_FILE = "",
  // 1            = no division
  // 2 and more   = division by 2**(FREQ_TABLE_FILE-1)
  parameter FREQ_DIVISOR_FACTOR = 1
  ) (
  input              clk_i,
  input              srst_i,
  input              sample_tick_i,
  input        [7:0] frequency_number_i,
  output logic [8:0] modulator_o
);

logic        [10:0] angle;
logic signed [8:0]  sine_signed;
logic               angle_incr_en;

frequency_control #(
  .FREQ_TABLE_FILE     ( FREQ_TABLE_FILE     ),
  .FREQ_DIVISOR_FACTOR ( FREQ_DIVISOR_FACTOR )
) fc (
  .clk_i               ( clk_i               ),
  .srst_i              ( srst_i              ),
  .sample_tick_i       ( sample_tick_i       ),
  .frequency_number_i  ( frequency_number_i  ),
  .angle_incr_en_o     ( angle_incr_en       )
);

always_ff @( posedge clk_i )
  if( srst_i )
    angle <= '0;
  else
    if( angle_incr_en )
      angle <= angle + 1'b1;

// Parameter values for ATAN and K were generated with
// ../../cordic_based_math/atan_generator.py program.
// Read file annotation for details
sincos #(
  .N                ( 9                           ),
  .DW               ( 9                           ),
  .AW               ( 9                           ),
  .ATAN             ( `include "atan_9b.vh"       ),
  .KW               ( 9                           ),
  .K                ( 311                         ),
  // Such small cordic wouldnt require pipelining on 25 MHz
  .CORDIC_PIPELINE  ( "none"                      ),
  .OUTPUT_REG_EN    ( 0                           )
) cordic_core (
  .clk_i            ( clk_i                       ),
  .valid_i          ( 1'b1                        ),
  .quadrant_i       ( angle[10:9]                 ),
  .angle_i          ( angle[8:0]                  ),
  .sin_o            (                             ),
  // Actually pick cosine
  .cos_o            ( sine_signed                 ),
  .valid_o          (                             )
);

// Scale up to unsigned values
always_ff @( posedge clk_i )
  modulator_o <= { sine_signed[8]^1'b1, sine_signed[7:0] };

endmodule











