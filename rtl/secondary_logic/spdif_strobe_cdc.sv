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
 * Special simplified CDC module to pass strobe from a higher frequency domain
 * to lower (but not twice nad more lower) and the incoming strobe is a
 * relatively rare event ( once per 4 cycles of clk_a_i at most )
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

module spdif_strobe_cdc #(
  // Tells how much is clk_b_i slower than clk_a_i. For example, RATIO==4
  // tells that clk_b_i could be up to 3-4 times slower, but not including 4.
  // Actually, there sould be some safe gap so that it's guaranteed that
  // strobe_i shall be captured at clk_b_i.
  parameter    RATIO = 3
) (
  input        clk_a_i,
  input        clk_b_i,
  input        strobe_i,
  output logic strobe_o
);

logic [RATIO-1:0] strobe_d;
logic             cdc_strobe_clk_a;
logic [1:0]       cdc_strobe_clk_b;

always_ff @( posedge clk_a_i )
  strobe_d <= {strobe_d[RATIO-2:0], strobe_i};

// Basically, it's just a strobe_i stretched to two clk_a_i
// cycles. We need no sample it on clk_b_i and generate
// stobe at positive edge to prevent double beat per one strobe_i
assign cdc_strobe_clk_a = |strobe_d;

always_ff @( posedge clk_b_i )
  cdc_strobe_clk_b <= { cdc_strobe_clk_b[0],  cdc_strobe_clk_a };

assign strobe_o = cdc_strobe_clk_b == 2'b01;

endmodule
