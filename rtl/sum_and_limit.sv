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

// Summator with owerflow protection

module sum_and_limit #(
  parameter             DWIDTH = 16
)(
  input        [DWIDTH-1:0] data1_i,
  input        [DWIDTH-1:0] data2_i,
  output logic [DWIDTH-1:0] data_o
);

logic [DWIDTH:0] tmp_sum;

assign tmp_sum = data1_i + data2_i;

always_comb
  case( { data2_i[DWIDTH-1], data1_i[DWIDTH-1] } )
    2'b00 :   data_o = tmp_sum[DWIDTH-1] ? ( '1 >> 1 ) : tmp_sum[DWIDTH-1:0];
    2'b11 :   data_o = tmp_sum[DWIDTH-1] ? tmp_sum[DWIDTH-1:0] : ( 1'b1 << DWIDTH );
    default : data_o = tmp_sum[DWIDTH-1:0];
  endcase

endmodule

