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

module low_pass_filter #(
  parameter             DWIDTH = 16,
  parameter             DEPTH  = 32
)(
  input                     clk_i,
  input                     srst_i,
  input                     sample_tick_i,
  input                     enable_i,
  input [DWIDTH-1:0]        data_i,
  output logic [DWIDTH-1:0] data_o
);

logic [DWIDTH-1:0]               data_d [DEPTH-1:0];
logic [DWIDTH-1+$clog2(DEPTH):0] sum    [DEPTH:0];

logic [DWIDTH-1:0] data_abs;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    begin
      data_d[0] <= data_i;//{~data_i[DWIDTH-1], data_i[DWIDTH-2:0]};
      for( int i = 0; i < DEPTH-1; i++ )
        data_d[i+1] <= data_d[i];
    end

always_comb
  begin
    sum[0] = 0;
    for( int i = 0; i < DEPTH; i++ )
      sum[i+1] = sum[i] + data_d[i];
  end

always_ff @( posedge clk_i )
  data_abs <= sum[DEPTH] >> $clog2(DEPTH);

assign data_o = enable_i ? data_abs : data_i;// {~data_abs[DWIDTH], data_abs[DWIDTH-1:0]} : data_i;

endmodule
