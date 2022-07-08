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

module chorus #(
  parameter           DWIDTH   = 16,
  parameter           MIN_TIME = 'h370,
  parameter           MAX_TIME = 'h530
) (
  input               clk_i,
  input               srst_i,
  input               sample_tick_i,
  input               enable_i,

  input [7:0]         level_i,
  input [7:0]         depth_i,

  input [DWIDTH-1:0]        data_i,
  output logic [DWIDTH-1:0] data_o
);

localparam DELAY_AWIDTH = $clog2( MAX_TIME );

logic [DELAY_AWIDTH-1:0] delay_time;

logic [7:0] counter;
logic       change_length_en;

always_ff @( posedge clk_i )
  if( srst_i )
    counter <= '0;
  else
    if( sample_tick_i )
      counter <= change_length_en ? '0 : counter + 1'b1;

assign change_length_en = ( counter == depth_i );

enum logic [1:0] { GO_DOWN_S, GO_UP_S, IDLE_S } state, state_next;

always_ff @( posedge clk_i )
  if( srst_i )
    state <= IDLE_S;
  else
    state <= state_next;

always_comb
  begin
    state_next = state;
    if( !enable_i )
      state_next = IDLE_S;
    else
      case( state )
        IDLE_S    :                              state_next = GO_UP_S;
        GO_UP_S   : if( delay_time >= MAX_TIME ) state_next = GO_DOWN_S;
        GO_DOWN_S : if( delay_time <= MIN_TIME ) state_next = GO_UP_S;
        default   :                              state_next = IDLE_S;
      endcase
  end

always_ff @( posedge clk_i )
  if( state==IDLE_S )
    delay_time <= MIN_TIME;
  else
    if( sample_tick_i && change_length_en )
      case( state )
        GO_UP_S   : delay_time <= delay_time + 1'b1;
        GO_DOWN_S : delay_time <= delay_time - 1'b1;
      endcase

logic [DWIDTH-1:0] delay_data;
logic [DWIDTH-1:0] output_data;

delay #(
  .DWIDTH              ( DWIDTH                      ),
  .USE_EXTERNAL_MEMORY ( 0                           ),
  .AWIDTH              ( DELAY_AWIDTH                ),
  .FILTER_EN           ( 0                           ),
  .FILTER_DEPTH        ( 16                          ),
  .UNMUTE_EN           ( 0                           ),
  .NO_FEEDBACK         ( 1                           )
) delay (
  .clk_i               ( clk_i                       ),
  .srst_i              ( srst_i                      ),
  .sample_tick_i       ( sample_tick_i               ),
  .enable_i            ( 1'b1                        ),
  .level_i             ( level_i                     ),
  .time_i              ( delay_time                  ),
  .filter_en_i         ( 1'b0                        ),
  .data_i              ( data_i                      ),
  .data_o              ( delay_data                  )
);

sum_and_limit #(
  .DWIDTH             ( DWIDTH               )
) output_sum (
  .data1_i            ( data_i               ),
  .data2_i            ( delay_data           ),
  .data_o             ( output_data          )
);

assign data_o = enable_i ? output_data : data_i;

endmodule
