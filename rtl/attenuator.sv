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

module attenuator #(
  parameter             DWIDTH = 16,
  parameter             MULT_W = 9
) (
  input signed [DWIDTH-1:0]        data_signed_i,
  input signed [MULT_W-1:0]        mult_i,
  output logic [DWIDTH-1:0] data_o
);

logic signed [DWIDTH+MULT_W-1:0] mult;

assign mult   = data_signed_i * mult_i;
assign data_o = mult >> (MULT_W-1);

endmodule
