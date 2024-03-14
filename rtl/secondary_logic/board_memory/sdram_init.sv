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

// W9864G6JT init procedure

module sdram_init #(
  parameter BURST_LENGTH     = 3'b000,   // 1
  parameter ADDRESSING_MODE  = 1'b1, // sequential
  parameter CAS_LATENCY      = 3'b010, // 2 cycles
  parameter WRITE_MODE       = 1 // burst read and single write
) (
  input               clk_i,
  input               run_i,
  output logic        done_o,
  output logic [11:0] a_o,
  output logic [1:0]  bs_o,
  output logic [3:0]  cmd_o
);

// Self reset after getting run_i signal
logic run_d;
logic srst;
always_ff @( posedge clk_i )
  run_d <= run_i;
assign srst = ( {run_d, run_i} == 2'b01 );


enum logic [2:0] {
  IDLE_S,
  INITIAL_PAUSE_S,
  PRECHARGE_S,
  AUTO_REFRESH_S,
  PROGRAM_S,
  DONE_S
} state, state_next;

// Multi-purpose_counter
logic [2:0] counter;
always_ff @( posedge clk_i )
  counter <= state_next != state ? '0 : counter + 1'b1;

logic [2:0] ar_cnt;
always_ff @( posedge clk_i )
  if( state==AUTO_REFRESH_S && counter=='1)
    ar_cnt <= ar_cnt + 1'b1;

// 200 us = ~33333 166 MHz clock cycles. round it to 65536
logic [16:0] initial_counter;
logic pause_done;

always_ff @( posedge clk_i )
  if( srst )
    initial_counter <= '0;
  else
    if( initial_counter > 0 )
      initial_counter <= initial_counter + 1'b1;
    else
      if( run_i )
        initial_counter <= 1'b1;

always_ff @( posedge clk_i )
  if( srst )
    pause_done <= 1'b0;
  else
    if( initial_counter[16] )
      pause_done <= 1'b1;

always_ff @( posedge clk_i )
  state <= srst ? IDLE_S : state_next;

localparam TRSC = 3;

always_comb
  begin
    state_next = state;
    case( state )
      IDLE_S          : if( run_i )                  state_next = INITIAL_PAUSE_S;
      INITIAL_PAUSE_S : if( pause_done )             state_next = PRECHARGE_S;
      PRECHARGE_S     : if( counter==7)              state_next = AUTO_REFRESH_S;
      AUTO_REFRESH_S  : if( ar_cnt==7 && counter==6) state_next = PROGRAM_S;
      PROGRAM_S       : if( counter==7)              state_next = DONE_S;
      DONE_S          :;
      default:;
    endcase
  end

localparam DESELECT              = 4'b1111;
localparam NOP                   = 4'b0111;
localparam PRECHARGE             = 4'b0010;
localparam AUTO_REFRESH          = 4'b0001;
localparam PROGRAM_MODE_REGISTER = 4'b0000;

always_comb
  begin
    // defaults
    a_o   = '0;
    bs_o  = '0;
    cmd_o = DESELECT;
    case( state )
    IDLE_S          :;
    INITIAL_PAUSE_S :;

    PRECHARGE_S     :
      if( counter==0 )
        { a_o[10], cmd_o } = { 1'b1, PRECHARGE };

    AUTO_REFRESH_S  :
      if( counter==0 )
        cmd_o = AUTO_REFRESH;

    PROGRAM_S :
      if( counter==1)
        begin
          cmd_o = PROGRAM_MODE_REGISTER;
          a_o[2:0] = BURST_LENGTH;
          a_o[3]   = ADDRESSING_MODE;
          a_o[6:4] = CAS_LATENCY;
          a_o[9]   = WRITE_MODE[0];
        end

    DONE_S:;
    default:;
    endcase
  end

assign done_o = state==DONE_S;

endmodule





