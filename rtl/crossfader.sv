/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 * XXX: add annotation
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
  .data_signed_i     ( data_1_i               ),
  .mult_i            ( { 1'b0, data_1_level } ),
  .data_o            ( data_1_gained          )
);

attenuator #(
  .DWIDTH            ( DWIDTH                 )
) data_2_gain (
  .data_signed_i     ( data_2_i               ),
  .mult_i            ( { 1'b0, level_i }      ),
  .data_o            ( data_2_gained          )
);

// Because one of these right hand signals is always attenuated, no need in
// overflow protection
assign data_o = data_1_gained + data_2_gained;

endmodule
