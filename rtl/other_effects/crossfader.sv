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
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

/*
* Gain properties
 *
 *  *** -- data_1_i
 *  --- -- data_2_i
 *
 *     gain
 *  1   |---                           ***
 *      |   ---                     ***
 *      |      ---               ***
 *      |         ---         ***
 *      |            ---   ***
 *  0.5 |               *-*
 *      |            ***   ---
 *      |         ***         ---
 *      |      ***               ---
 *      |   ***                     ---
 *    0 |***___________________________---______
 *        0             128            255      level_i
 *
 */
module crossfader #(
  parameter    DWIDTH = 16
) (
  input        [DWIDTH-1:0] data_1_i,
  input        [DWIDTH-1:0] data_2_i,
  input        [7:0]        level_i,
  output logic [DWIDTH-1:0] data_o
);
logic [DWIDTH-1:0] data_1_gained;
logic [DWIDTH-1:0] data_2_gained;

logic [7:0] data_1_level;
assign data_1_level = 8'd255 - level_i;

attenuator #(
  .DWIDTH            ( DWIDTH                 )
) data_1_gain (
  .data_i            ( data_1_i               ),
  .mult_i            ( { 1'b0, data_1_level } ),
  .data_o            ( data_1_gained          )
);

attenuator #(
  .DWIDTH            ( DWIDTH                 )
) data_2_gain (
  .data_i            ( data_2_i               ),
  .mult_i            ( { 1'b0, level_i }      ),
  .data_o            ( data_2_gained          )
);

// Because one of these right hand signals is always attenuated, no need in
// overflow protection
assign data_o = data_1_gained + data_2_gained;

endmodule
