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

module switch_debouncer #(
  parameter NUM            = 2,
  parameter DEBOUNCE_DEPTH = 13
) (
  input                  clk_i,
  input                  srst_i,
  input [NUM-1:0]        data_i,
  output logic [NUM-1:0] data_o
);

typedef enum logic [1:0] {
  UNPRESSED_S,
  PRESS_S,
  PRESSED_S,
  UNPRESS_S
} state_t;

genvar i;
generate
  for( i = 0; i < NUM; i++)
    begin : gen_debounce
      logic [DEBOUNCE_DEPTH-1:0] cnt;
      state_t state, state_next;

      always_ff @( posedge clk_i )
        if( srst_i )
          state <= UNPRESSED_S;
        else
          state <= state_next;

      always_comb
        begin
          state_next = state;
          case ( state )
            UNPRESSED_S : if( data_i[i] )  state_next = PRESS_S;
            PRESS_S     : if( cnt=='1 )    state_next = PRESSED_S;
            PRESSED_S   : if( !data_i[i] ) state_next = UNPRESS_S;
            UNPRESS_S   : if( cnt=='1 )    state_next = UNPRESSED_S;
          endcase
        end

      always_ff @( posedge clk_i )
        cnt <= ( state==PRESS_S || state==UNPRESS_S ) ? cnt + 1'b1 : '0;

      assign data_o[i] = ( state==PRESS_S || state==PRESSED_S );
    end // gen_debounce
endgenerate
endmodule
