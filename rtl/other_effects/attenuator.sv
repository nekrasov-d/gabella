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
 * Basically, a multiplier. But it this project we'd rather need to multiply to
 * 0.xxxx value. It is implemented by right shift. But it shifts not all the way
 * down if OFFSET is > 0. If OFFSET = 1 the output ranges from 0 to data_signed x 2
 * if OFFSET = 2 the output ranges form 0 to data_signed x 4 (with some loss of
 * fractional part precision of course)
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

module attenuator #(
  parameter             DWIDTH = 16,
  parameter             MULT_W = 9,
  parameter             OFFSET = 1
) (
  input signed [DWIDTH-1:0] data_i,
  input signed [MULT_W-1:0] mult_i,
  output logic [DWIDTH-1:0] data_o
);

localparam MULT_REG_WIDTH = DWIDTH + MULT_W;

logic signed [DWIDTH+MULT_W-1:0] mult;

assign mult   = data_i * mult_i;
//assign data_o = mult >> (MULT_W-1);
assign data_o = mult[MULT_REG_WIDTH-2 -: DWIDTH];

endmodule
