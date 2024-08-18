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
  parameter FREQ_TABLE_FILE = "",
  // 1            = no division
  // 2 and more   = division by 2**(FREQ_TABLE_FILE-1)
  parameter FREQ_DIVISOR_FACTOR = 1
) (
  input        clk_i,
  input        srst_i,
  input        sample_tick_i,
  input [7:0]  frequency_number_i,
  output logic angle_incr_en_o
);

localparam RESOLUTION = 2**16;
localparam BITWIDTH   = 16;

logic [BITWIDTH:0] angle_increment_probability;
logic generate_bit_en;

// Nested declaration
//`include "rom.sv"

rom_tremolo #(
  .DWIDTH       ( BITWIDTH+1                  ),
  .AWIDTH       ( 8                           ),
  .INIT_FILE    ( FREQ_TABLE_FILE             )
) frequency_table (
  .clk_i        ( clk_i                       ),
  .rdaddr_i     ( frequency_number_i          ),
  .rddata_o     ( angle_increment_probability )
);

generate
  if( FREQ_DIVISOR_FACTOR==1 )
    assign generate_bit_en = sample_tick_i;
  else
    begin
      logic [FREQ_DIVISOR_FACTOR-1:0] counter;
      always_ff @( posedge clk_i )
        if( srst_i )
          counter <= '0;
        else
          if( sample_tick_i )
            counter <= counter + 1'b1;

      assign generate_bit_en = counter[FREQ_DIVISOR_FACTOR-1] && sample_tick_i;
    end
endgenerate


biased_bitstream_generator #(
  .TOKENS_FOR_1          ( 2**RESOLUTION               )
) bbg (
  .clk_i                 ( clk_i                       ),
  .srst_i                ( srst_i                      ),
  .generate_bit_i        ( generate_bit_en           ),
  .probability_of_1_i    ( angle_increment_probability ),
  .output_bit_o          ( angle_incr_en_o             )
);

endmodule

