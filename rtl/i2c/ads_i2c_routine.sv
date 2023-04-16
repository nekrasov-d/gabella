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

module ads_i2c_routine #(
  parameter ROBOT_READ_EN      = 1,
  parameter SYS_CLK_FREQ_HZ    = 25000000,
  parameter ROBOT_READ_FREQ_HZ = 100
  )(
  input                   clk_i,
  input                   srst_i,
  avalon_mm_if            csr_if,
  avalon_mm_if            ads_if,
  output logic [7:0][7:0] knob_level_o
);
// See TABLE 2 in ADS7830 documentation
logic [7:0][7:0] knob_level;
logic [7:0][7:0] knob_level_remap;

assign csr_if.readdata = ( csr_if.address < 'h4 ) ? knob_level_remap[3:0] :
                                                    knob_level_remap[7:4];

assign csr_if.waitrequest   = '0;
always_ff @( posedge clk_i )
  csr_if.readdatavalid <= csr_if.read;

//*****************************************************************************
//*****************************************************************************
// ADS7830 robot read state machine

enum logic { TIMER_S, READ_KNOB_S } state, state_next;

logic [2:0] current_knob;
logic       knob_read_en;

logic [$clog2(SYS_CLK_FREQ_HZ/ROBOT_READ_FREQ_HZ)-1:0] timer;

always_ff @( posedge clk_i )
  if( ads_if.readdatavalid )
    knob_level[current_knob] <= ads_if.readdata;

always_ff @( posedge clk_i )
  if( srst_i )
    state <= TIMER_S;
  else
    state <= state_next;

always_comb
  begin
    state_next = state;
    case( state )
      TIMER_S     : if( ROBOT_READ_EN && knob_read_en ) state_next = READ_KNOB_S;
      READ_KNOB_S : if( ads_if.readdatavalid )          state_next = TIMER_S;
    endcase
  end

always_ff @( posedge clk_i )
  if( srst_i )
    timer <= 1'b0;
  else
    timer <= ads_if.readdatavalid ? '0 : timer + 1'b1;

assign knob_read_en = ( timer ==  SYS_CLK_FREQ_HZ / ROBOT_READ_FREQ_HZ );

always_ff @( posedge clk_i )
  if( srst_i )
    current_knob <= '0;
  else
    if( ads_if.readdatavalid )
      current_knob <= current_knob + 1'b1;

assign ads_if.address = current_knob;
assign ads_if.read    = ( state == READ_KNOB_S );

assign knob_level_remap[0] = knob_level[0];
assign knob_level_remap[1] = knob_level[4];
assign knob_level_remap[2] = knob_level[1];
assign knob_level_remap[3] = knob_level[5];
assign knob_level_remap[4] = knob_level[2];
assign knob_level_remap[5] = knob_level[6];
assign knob_level_remap[6] = knob_level[3];
assign knob_level_remap[7] = knob_level[7];

assign knob_level_o = knob_level_remap;
endmodule
