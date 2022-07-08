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
  input [DWIDTH-1:0]        data_signed_i,
  input [MULT_W-1:0]        mult_i,
  output logic [DWIDTH-1:0] data_o
);

logic        sign;
logic [DWIDTH-2:0] magnitude;

logic [DWIDTH + MULT_W - 1 :0] mult_output;
logic [DWIDTH-2:0]             output_magnitude;

assign sign = data_signed_i[DWIDTH-1];

assign magnitude = sign ? ~data_signed_i[DWIDTH-2:0] : data_signed_i[DWIDTH-2:0];

assign mult_output = magnitude * mult_i;

assign output_magnitude = mult_output >> (MULT_W-1);

assign data_o[DWIDTH-1]   = sign;
assign data_o[DWIDTH-2:0] = sign ? ~output_magnitude : output_magnitude;

endmodule
