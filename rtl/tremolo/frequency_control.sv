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
 * This module transforms input number of the lookup table frequency into
 * increment enable signal which controls sawtooth generator (which in turn
 * controls cordic). Lookup table values contain increment enable probability
 * per sample tick and are pre-calculated offline.
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 22:25:19 +0300
*/

module frequency_control #(
  parameter                   PERIOD_BITWIDTH = 18
) (
  input                       clk_i,
  input                       srst_i,
  input                       sample_tick_i,
  input [PERIOD_BITWIDTH-1:0] required_period_in_samples_i,
  output logic                angle_incr_en_o
);

localparam RESOLUTION = 2**16;
localparam BITWIDTH   = 16;

logic [BITWIDTH:0] angle_increment_probability;

// 2**27 becase RESOLUTION is 2**16 and the amount of samples in one
// cordic round trip (when increment probability is 1) is 2*11.
// 11 + 16 = 27
localparam MAX_VAL = 2**27;
localparam NBITS   = 28;

divider #(
  .MAX_VAL        ( MAX_VAL                      ),
  .NBITS          ( NBITS                        )
) DUT (
  .clk_i          ( clk_i                        ),
  .srst_i         ( srst_i                       ),
  .valid_i        ( 1'b1                         ),
  .numerator_i    ( 2**27                        ),
  .denominator_i  ( required_period_in_samples_i ),
  .quotient_o     ( angle_increment_probability  ),
  .remainder_o    (                              )
);

biased_bitstream_generator #(
  .TOKENS_FOR_1          ( RESOLUTION                  )
) bbg (
  .clk_i                 ( clk_i                       ),
  .srst_i                ( srst_i                      ),
  .generate_bit_i        ( sample_tick_i               ),
  .probability_of_1_i    ( angle_increment_probability ),
  .output_bit_o          ( angle_incr_en_o             )
);

endmodule

