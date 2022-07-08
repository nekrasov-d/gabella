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
 * Device power-up blinking
*/

module led_controller #(
  parameter             DWIDTH = 15,
  parameter             STARTUP_MUSIC_EN = 0
) (
  input                 clk_i,
  input                 srst_i,
  input                 sample_tick_i,
  input                 mode_i, // 0 - regular, 1 - constant blink
  input [3:0]           leds_i,
  output logic [3:0]    leds_o,

  input [DWIDTH-1:0]        data_i,
  output logic [DWIDTH-1:0] data_o
);


logic [21:0] counter;

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
} state, state_next;

always_ff @( posedge clk_i )
  if( srst_i )
    state <= IDLE_S;
  else
    state <= state_next;

always_comb
  begin
    state_next = state;
    case( state )
      IDLE_S    :                     state_next = mode_i ? FLICK_1_S : BURN_1_S;
      BURN_1_S  : if( counter == '1 ) state_next = BURN_2_S;
      BURN_2_S  : if( counter == '1 ) state_next = BURN_3_S;
      BURN_3_S  : if( counter == '1 ) state_next = BURN_4_S;
      BURN_4_S  : if( counter == '1 ) state_next = FLICK_1_S;
      FLICK_1_S : if( counter == '1 ) state_next = FLICK_2_S;
      FLICK_2_S : if( counter == '1 ) state_next = FLICK_3_S;
      FLICK_3_S : if( counter == '1 ) state_next = FLICK_4_S;
      FLICK_4_S : if( counter == '1 ) state_next = mode_i ? FLICK_1_S : BYPASS_S;
      BYPASS_S  : if( mode_i )        state_next = FLICK_1_S;
    endcase
 end

always_ff @( posedge clk_i )
  counter <= ( state_next != state ) ? '0 : counter + 1'b1;


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


//***********************************************************************
// bleep

typedef logic [15:0] sin_table_t [31:0];

localparam sin_table_t SIN_TABLE = '{
  16'h0000,
  16'h07dd,
  16'h0f68,
  16'h1651,
  16'h1c50,
  16'h2127,
  16'h24a2,
  16'h269d,
  16'h2704,
  16'h25d1,
  16'h2313,
  16'h1ee4,
  16'h1972,
  16'h12f6,
  16'h0bb2,
  16'h03f4,
  16'hfc0c,
  16'hf44e,
  16'hed0a,
  16'he68e,
  16'he11c,
  16'hdced,
  16'hda2f,
  16'hd8fc,
  16'hd963,
  16'hdb5e,
  16'hded9,
  16'he3b0,
  16'he9af,
  16'hf098,
  16'hf823,
  16'hff00
};

logic [2:0] cnt;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    cnt <= cnt + 1'b1;


logic [4:0] sin_pointer;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    case( state )
      BURN_1_S : sin_pointer <= ( cnt[2] ) ? sin_pointer + 1'b1 : sin_pointer;
      BURN_2_S : sin_pointer <= ( cnt[1] ) ? sin_pointer + 1'b1 : sin_pointer;
      BURN_3_S : sin_pointer <= ( cnt[0] ) ? sin_pointer + 1'b1 : sin_pointer;
      BURN_4_S : sin_pointer <=              sin_pointer + 1'b1;
      default  :;
    endcase

always_comb
  case ( state )
    BURN_1_S, BURN_2_S, BURN_3_S, BURN_4_S  : data_o = STARTUP_MUSIC_EN ? SIN_TABLE[sin_pointer] : data_i;
    default                                 : data_o = data_i;
  endcase

endmodule
