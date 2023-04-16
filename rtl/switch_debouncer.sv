/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
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
