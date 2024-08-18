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
 * This module takes "probability", ranged from 0.0 to 1.0 and scaled to
 * "TOKENS_FOR_1" value as 1. Every time module receives generate_bit_i signal
 * it generates 1 at output_bit_o with given probability. In total the relation
 * of amount of ones to amount of zeroes approaches to the given "probability".
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 22:23:47 +0300
*/

module biased_bitstream_generator #(
  // Assignable
  parameter TOKENS_FOR_1 = 2**16, // Precision
  // Non-assignable
  parameter PROBABILITY_W = $clog2(TOKENS_FOR_1) + 1, // + 1 to code 'b1000...000
  parameter BUCKET_W      = PROBABILITY_W + 1
) (
  input                     clk_i,
  input                     srst_i,
  input                     generate_bit_i,
  input [PROBABILITY_W-1:0] probability_of_1_i,
  output logic              output_bit_o
);

logic [BUCKET_W-1:0] token_bucket;
logic                enough_to_generate_1;

assign enough_to_generate_1 = ( token_bucket >= TOKENS_FOR_1 );

always_ff @( posedge clk_i )
  if( srst_i )
    token_bucket <= probability_of_1_i;
  else
    if( generate_bit_i )
      token_bucket <= enough_to_generate_1 ? token_bucket + probability_of_1_i - TOKENS_FOR_1 :
                                             token_bucket + probability_of_1_i;

assign output_bit_o = generate_bit_i && enough_to_generate_1;

endmodule
