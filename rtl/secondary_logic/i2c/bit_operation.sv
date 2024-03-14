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

import i2c_core_pkg::*;

module bit_operation #(
  parameter           SYS_CLK_FREQ_HZ  = 25000000,
  parameter           I2C_FREQ_HZ      = 100000,
  parameter           MAX_TR_OPS       = 49,
  parameter           MAX_READ_BITS    = 16
) (
  input               clk_i,
  input               srst_i,
  // Input data
  input bit_op_t      bit_op_i,
  input               push_bit_op_i,
  // output data
  output logic        rx_bit_o,
  output logic        rx_bit_queue_empty_o,
  input  logic        pull_rx_bit_i,
  // control
  input               start_i,
  output logic        busy_o,
  output logic        done_o,
  output logic        error_o,
  // BUS
  output logic        scl_o,
  inout               sda_io
);

localparam CYCLE_LENGTH   = SYS_CLK_FREQ_HZ / I2C_FREQ_HZ;
localparam ONE_QUARTER    = CYCLE_LENGTH / 4;
localparam HALF           = CYCLE_LENGTH / 2;
localparam THREE_QUARTERS = ONE_QUARTER * 3;

enum logic [2:0] {
  IDLE_S,
  START_S,
  SEND_BIT_0_S,
  SEND_BIT_1_S,
  RECEIVE_ACK_S,
  RECEIVE_BIT_S,
  STOP_S,
  ERROR_S
} state, state_next;

logic scl;
logic sda;
logic sda_oe;
logic operation_done;
logic self_reset;
logic ack_error;

bit_op_t bit_op;
logic    bit_op_rdreq;
logic    op_fifo_empty;

logic [$clog2(CYCLE_LENGTH)-1:0] counter;

always_ff @( posedge clk_i )
  if( srst_i )
    counter <= 1'b0;
  else
    counter <= operation_done ? '0 : counter + 1'b1;

assign operation_done = start_i || ( counter == CYCLE_LENGTH );

assign bit_op_rdreq = operation_done && (state != IDLE_S);

logic [$bits(bit_op_t)-1:0]  _bit_op;

showahead_sc_fifo #(
  .RAMSTYLE     ( "REGISTERS"                    ),
  .AWIDTH       ( $clog2(MAX_TR_OPS)             ),
  .DWIDTH       ( $bits(bit_op_t)                ),
  .RW_PROTECTED ( 1                              )
) input_fifo (
  .clk_i        ( clk_i                          ),
  .srst_i       ( srst_i | self_reset | done_o   ),
  .data_i       ( bit_op_i                       ),
  .wr_req_i     ( push_bit_op_i                  ),
  .empty_o      ( op_fifo_empty                  ),
  .full_o       (                                ),
  .rd_req_i     ( bit_op_rdreq                   ),
  .data_o       ( _bit_op                        ),
  .usedw_o      (                                )
);

assign bit_op = bit_op_t'(_bit_op);

//*****************************************************************************
//*********************************** FSM *************************************

always_ff @( posedge clk_i )
  if( srst_i )
    state <= IDLE_S;
  else
    if( start_i || operation_done )
      state <= state_next;

always_comb
  begin
    state_next = state;
    case( state )
      IDLE_S  : if( start_i ) state_next = START_S;
      START_S :
        if( op_fifo_empty )
          state_next = ERROR_S;
        else
          case( bit_op )
            TX_0    : state_next = SEND_BIT_0_S;
            TX_1    : state_next = SEND_BIT_1_S;
            default : state_next = ERROR_S;
          endcase
      SEND_BIT_0_S :
        if( op_fifo_empty )
          state_next = STOP_S;
        else
          case( bit_op )
            TX_0    : state_next = SEND_BIT_0_S;
            TX_1    : state_next = SEND_BIT_1_S;
            RX_ACK  : state_next = RECEIVE_ACK_S;
            RX      : state_next = RECEIVE_BIT_S;
            default : state_next = ERROR_S;
          endcase
      SEND_BIT_1_S :
        if( op_fifo_empty )
          state_next = STOP_S;
        else
          case( bit_op )
            TX_1    : state_next = SEND_BIT_1_S;
            TX_0    : state_next = SEND_BIT_0_S;
            RX_ACK  : state_next = RECEIVE_ACK_S;
            RX      : state_next = RECEIVE_BIT_S;
            default : state_next = ERROR_S;
          endcase
      RECEIVE_ACK_S :
        if( op_fifo_empty )
          state_next = STOP_S;
        else
          case( bit_op )
            TX_0    : state_next = SEND_BIT_0_S;
            TX_1    : state_next = SEND_BIT_1_S;
            RX      : state_next = RECEIVE_BIT_S;
            RS      : state_next = START_S;
            default : state_next = ERROR_S;
          endcase
      RECEIVE_BIT_S :
        if( op_fifo_empty )
          state_next = ERROR_S;
        else
          case( bit_op )
            RX      : state_next = RECEIVE_BIT_S;
            TX_0    : state_next = SEND_BIT_0_S; // SEND ACK
            TX_1    : state_next = SEND_BIT_1_S; // SEND NACK
            default : state_next = ERROR_S;
          endcase
      STOP_S  : state_next = IDLE_S;
      ERROR_S : state_next = IDLE_S; // sda and scl perform stop condition
    endcase
  end

assign busy_o  = (state != IDLE_S);
assign done_o  = (state==STOP_S || state==ERROR_S) && operation_done;

// If receive NACK for some reason
assign ack_error = state==RECEIVE_ACK_S && counter==HALF && sda_io;

always_ff @( posedge clk_i )
  if( start_i )
    error_o <= 1'b0;
  else
    if( state==ERROR_S || ack_error )
      error_o <= 1'b1;

assign self_reset = done_o && error_o;

//*****************************************************************************
//***************************** BUS CONTROL ***********************************

//  like this:
//  |    ______   |
//  |___|     |___|
//  |<-- cycle -->|
logic center_aligned_pulse_pattern;
assign center_aligned_pulse_pattern = ( counter < ONE_QUARTER    ) ? 1'b0 :
                                      ( counter < THREE_QUARTERS ) ? 1'b1 : 1'b0;

always_comb
  begin
    case( state )
      IDLE_S :
        begin
          sda_oe = 1'b1;
          sda    = 1'b1;
          scl    = 1'b1;
        end
      START_S :
        begin
          sda_oe  = 1'b1;
          sda     = ( counter > ONE_QUARTER ) ? 1'b0 : 1'b1;
          scl     = ( counter > HALF        ) ? 1'b0 : 1'b1;
        end
      SEND_BIT_0_S :
        begin
          sda_oe  = 1'b1;
          sda     = 1'b0;
          scl     = center_aligned_pulse_pattern;
        end
      SEND_BIT_1_S :
        begin
          sda_oe  = 1'b1;
          sda     = 1'b1;
          scl     = center_aligned_pulse_pattern;
        end
      RECEIVE_ACK_S :
        begin
          sda_oe  = 1'b0;
          sda     = 1'bx;
          scl     = center_aligned_pulse_pattern;
        end
      RECEIVE_BIT_S :
        begin
          sda_oe  = 1'b0;
          sda     = 1'bx;
          scl     = center_aligned_pulse_pattern;
        end
      STOP_S, ERROR_S :
        begin
          sda_oe  = 1'b1;
          sda     = ( counter > THREE_QUARTERS ) ? 1'b1 : 1'b0;
          scl     = ( counter > ONE_QUARTER    ) ? 1'b1 : 1'b0;
        end
    endcase
  end

logic sda_reg;
logic sda_oe_reg;

logic [15:0] scl_delay;
always_ff @( posedge clk_i )
  scl_delay <= {scl_delay[14:0], scl};

always_ff @( posedge clk_i )
  begin
    sda_reg    <= sda;
    sda_oe_reg <= sda_oe;
  end

assign sda_io = sda_oe_reg ? sda_reg : 1'bz;
assign scl_o  = scl_delay[15];

//*****************************************************************************
//************************* HANDLE RX DATA ************************************

logic rx_bit_val;
assign rx_bit_val = ( state == RECEIVE_BIT_S ) && ( counter == HALF );

showahead_sc_fifo #(
  .RAMSTYLE     ( "REGISTERS"                     ),
  .AWIDTH       ( $clog2(MAX_READ_BITS)           ),
  .DWIDTH       ( 1                               ),
  .RW_PROTECTED ( 1                               )
) output_fifo (
  .clk_i        ( clk_i                           ),
  .srst_i       ( srst_i | self_reset             ),
  .data_i       ( sda_io                          ),
  .wr_req_i     ( rx_bit_val                      ),
  .empty_o      ( rx_bit_queue_empty_o            ),
  .full_o       (                                 ),
  .rd_req_i     ( pull_rx_bit_i                   ),
  .data_o       ( rx_bit_o                        ),
  .usedw_o      (                                 )
);

endmodule
