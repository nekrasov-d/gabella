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
 * A dump low-pas filter with coarse band selection (power of two-s).
 * The trick is that a basic low-pass requires equal coefficients.
 * This way we can avoid waisting multipliers. Just sum all the delayed data and
 * shift right (that costs nothing).
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

module primitive_lowpass_filter #(
  parameter DWIDTH = 16,
  parameter DEPTH  = 32
)(
  input                     clk_i,
  input                     srst_i,
  input                     sample_tick_i,
  input                     enable_i,
  input signed [DWIDTH-1:0] data_i,
  output logic [DWIDTH-1:0] data_o
);

logic signed [DWIDTH-1+$clog2(DEPTH):0] data_d [DEPTH-1:0];
logic signed [DWIDTH-1+$clog2(DEPTH):0] sum    [DEPTH:0];
logic signed [DWIDTH-1:0] data_abs;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    begin
      data_d[0] <= data_i;
      for( int i = 0; i < DEPTH-1; i++ )
        data_d[i+1] <= data_d[i];
    end

always_comb
  begin
    sum[0] = 0;
    for( int i = 0; i < DEPTH; i++ )
      sum[i+1] = sum[i] + data_d[i];
  end

//always_ff @( posedge clk_i )
//  data_abs <= sum[DEPTH] >> $clog2(DEPTH);

always_ff @( posedge clk_i )
  data_abs <= sum[DEPTH][$bits(sum[DEPTH])-1 -: DWIDTH];

assign data_o = enable_i ? data_abs : data_i;

endmodule
