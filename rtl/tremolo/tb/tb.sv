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
 * The most primitive testbench ever... see main README.md
 *
 *  -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 22:27:08 +0300
*/

`timescale 1ns/1ns

module tb;
bit clk;
bit srst;

initial forever #1 clk = ~clk;

initial
  begin
    @( posedge clk ) srst <= 1'b1;
    @( posedge clk ) srst <= 1'b0;
  end

bit [7:0] freq_num;

initial
begin
  freq_num = 9'd20;
  #1000000;
  freq_num = 9'd200;
  #1000000;
  $stop;
end

tremolo #(
  .DW                  ( 24                               ),
  .FREQ_TABLE_FILE     ( "../tremolo_frequency_table.mem" ),
  .FREQ_DIVISOR_FACTOR ( 2                                )
) dut (
  .clk_i               ( clk                              ),
  .srst_i              ( srst                             ),
  .sample_tick_i       ( 1'b1                             ),
  .frequency_number_i  ( freq_num                         ),
  .level_i             ( 8'd128                           ),
  .enable_i            ( 1'b1                             ),
  .data_i              ( 24'd10000                        ),
  .data_o              (                                  )
);

endmodule
