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

module div2_and_sum #(
  parameter DATAW           = 16,
  parameter REGISTER_OUTPUT = 0
)(
  input                    clk_i,
  input        [DATAW-1:0] data1_i,
  input        [DATAW-1:0] data2_i,
  output logic [DATAW-1:0] data_o
);

logic [DATAW-1:0] data1_div;
logic [DATAW-1:0] data2_div;
logic [DATAW-1:0] sum;

assign data1_div = data1_i[DATAW-1] ? {2'b11, data1_i[DATAW-2:1]} :
                                      {2'b00, data1_i[DATAW-2:1]};

assign data2_div = data2_i[DATAW-1] ? {2'b11, data2_i[DATAW-2:1]} :
                                      {2'b00, data2_i[DATAW-2:1]};

assign sum = data1_div + data2_div;

generate
  if( REGISTER_OUTPUT )
    begin : reg_output
      always_ff @( posedge clk_i )
        data_o <= sum;
    end // reg_output
  else
    begin : comb_output
      assign data_o = sum;
    end
endgenerate
endmodule


