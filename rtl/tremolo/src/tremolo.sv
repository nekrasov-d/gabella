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
 * Top level module. Contain sine wave generator and two gain stages, one for
 * generated modulation signal, and one for the modulation itself.
 *
 *  -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 22:25:55 +0300
*/

module tremolo #(
  // Data width
  parameter DW              = 16,
  //
  parameter FREQ_TABLE_FILE = "",
  // 1            = no division
  // 2 and more   = division by 2**(FREQ_TABLE_FILE-1)
  parameter FREQ_DIVISOR_FACTOR = 1
) (
  input        clk_i,
  input        srst_i,
  input        sample_tick_i,
  input [7:0]  frequency_number_i,
  input [7:0]  level_i,
  input        enable_i,
  input signed [DW-1:0] data_i,
  output logic signed [DW-1:0] data_o
);

logic [8:0] modulator;

modulation #(
  .FREQ_TABLE_FILE     ( FREQ_TABLE_FILE     ),
  .FREQ_DIVISOR_FACTOR ( FREQ_DIVISOR_FACTOR )
) mod (
  .clk_i               ( clk_i               ),
  .srst_i              ( srst_i              ),
  .sample_tick_i       ( sample_tick_i       ),
  .frequency_number_i  ( frequency_number_i  ),
  .modulator_o         ( modulator            )
);

logic [8:0]  gain;
logic [16:0] mult1;

assign mult1 = modulator * level_i;
assign gain = 10'd511 - (mult1 >> 8);

logic signed [DW+9-1:0] mult2;
logic signed [DW-1:0]   modulated_data;

assign mult2 = data_i * $signed({1'b0, gain});
assign modulated_data = mult2 >> 9;

assign data_o = enable_i ? modulated_data : data_i;

endmodule
