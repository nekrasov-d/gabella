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

module limiter #(
  parameter DWIDTH    = 16,
  parameter THRESHOLD = 16000
) (
  input en_i,
  input [DWIDTH-1:0] data_i,
  output logic [DWIDTH-1:0] data_o
);

logic sign;
logic [DWIDTH-2:0] magnitude;
logic [DWIDTH-2:0] magnitude_lim;
logic [DWIDTH-1:0] data_lim;

assign sign = data_i[DWIDTH-1];
assign magnitude = sign ? ~data_i[DWIDTH-2:0] : data_i[DWIDTH-2:0];

assign magnitude_lim = ( magnitude > THRESHOLD ) ? THRESHOLD : magnitude;

assign data_lim = sign ? {1'b1, ~magnitude_lim} : {1'b0, magnitude_lim};

assign data_o = en_i ? data_lim : data_i;

endmodule
