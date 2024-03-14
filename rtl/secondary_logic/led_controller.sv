/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * Device power-up blinking
*/

module led_controller (
  input                 clk_i,
  input                 srst_i,
  input                 sample_tick_i,
  input                 mode_i, // 0 - regular, 1 - constant blink
  input [3:0]           leds_i,
  output logic [3:0]    leds_o
);

logic [21:0] counter;
logic change_state;

enum logic [3:0] {
  IDLE_S,
  BURN_1_S,
  BURN_2_S,
  BURN_3_S,
  BURN_4_S,
  FLICK_1_S,
  FLICK_2_S,
  FLICK_3_S,
  FLICK_4_S,
  BYPASS_S
} state;

always_ff @( posedge clk_i )
  if( srst_i )
    state <= IDLE_S;
  else
    case( state )
      IDLE_S    :                    state <= mode_i ? FLICK_1_S : BURN_1_S;
      BURN_1_S  : if( change_state ) state <= BURN_2_S;
      BURN_2_S  : if( change_state ) state <= BURN_3_S;
      BURN_3_S  : if( change_state ) state <= BURN_4_S;
      BURN_4_S  : if( change_state ) state <= FLICK_1_S;
      FLICK_1_S : if( change_state ) state <= FLICK_2_S;
      FLICK_2_S : if( change_state ) state <= FLICK_3_S;
      FLICK_3_S : if( change_state ) state <= FLICK_4_S;
      FLICK_4_S : if( change_state ) state <= mode_i ? FLICK_1_S : BYPASS_S;
      BYPASS_S  : if( mode_i )       state <= FLICK_1_S;
      default   :;
    endcase

always_ff @( posedge clk_i )
  counter <= change_state ? '0 : counter + 1'b1;

assign change_state = ( counter == '1 );

always_comb
  case ( state )
    IDLE_S    : leds_o = { 1'b0, 1'b0, 1'b0, 1'b0 };
    BURN_1_S  : leds_o = { 1'b0, 1'b0, 1'b0, 1'b1 };
    BURN_2_S  : leds_o = { 1'b0, 1'b0, 1'b1, 1'b0 };
    BURN_3_S  : leds_o = { 1'b0, 1'b1, 1'b0, 1'b0 };
    BURN_4_S  : leds_o = { 1'b1, 1'b0, 1'b0, 1'b0 };
    FLICK_1_S : leds_o = { 1'b0, 1'b0, 1'b0, 1'b0 };
    FLICK_2_S : leds_o = { 1'b1, 1'b1, 1'b1, 1'b1 };
    FLICK_3_S : leds_o = { 1'b0, 1'b0, 1'b0, 1'b0 };
    FLICK_4_S : leds_o = { 1'b1, 1'b1, 1'b1, 1'b1 };
    BYPASS_S  : leds_o = leds_i;
  endcase

endmodule
