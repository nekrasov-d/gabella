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

module i2c_core #(
  parameter           SYS_CLK_FREQ_HZ  = 25000000,
  parameter           I2C_FREQ_HZ      = 100000
  ) (
  input               clk_i,
  input               srst_i,
  // SGTL interface
  avalon_mm_if        amm_sgtl_if,
  // ADS interface
  avalon_mm_if        amm_ads_if,
  output logic        scl_o,
  inout               sda_io
);

localparam MAX_READ_BITS = 16;
localparam MAX_TR_OPS  = ($bits(sgtl_read_tr_t) / $bits(bit_op_t)) ;

localparam SGTL_WRITE_OP_CNT = ($bits(sgtl_write_tr_t) / $bits(bit_op_t));
localparam SGTL_READ_OP_CNT  = ($bits(sgtl_read_tr_t ) / $bits(bit_op_t));
localparam ADS_WRITE_OP_CNT  = ($bits(ads_write_tr_t ) / $bits(bit_op_t));
localparam ADS_READ_OP_CNT   = ($bits(ads_read_tr_t  ) / $bits(bit_op_t));

bit_op_t bit_op;
logic    push_logic_op;
logic    rx_bit;
logic    rx_empty;
logic    done;
logic    push_done;
logic    error;

logic [$clog2(MAX_TR_OPS)-1:0] counter;

enum logic [2:0] {
  IDLE_S,
  PUSH_TRANSACTION_S,
  WAIT_S,
  GET_READDATA_S,
  DONE_S
} state, state_next;

//*****************************************************************************
//******************************* HANDLE REQUEST ******************************
logic new_request;
logic read_case;
logic sgtl_case;
logic ads_case;

assign new_request = amm_sgtl_if.write | amm_sgtl_if.read | amm_ads_if.write | amm_ads_if.read;

enum logic [1:0] {
  SGTL_WRITE,
  SGTL_READ,
  ADS_WRITE,
  ADS_READ
} transaction_case;

always_ff @( posedge clk_i )
  if( state==IDLE_S && new_request )
    priority case ( 1'b1 )
      ( amm_sgtl_if.write ) : transaction_case <= SGTL_WRITE;
      ( amm_sgtl_if.read  ) : transaction_case <= SGTL_READ;
      ( amm_ads_if.write  ) : transaction_case <= ADS_WRITE;
      ( amm_ads_if.read   ) : transaction_case <= ADS_READ;
    endcase

assign read_case = transaction_case==SGTL_READ || transaction_case==ADS_READ;
assign sgtl_case = transaction_case==SGTL_READ || transaction_case==SGTL_WRITE;
assign ads_case  = transaction_case==ADS_READ  || transaction_case==ADS_WRITE;

//*****************************************************************************
//*********************************** FSM *************************************

always_ff @( posedge clk_i )
  if( srst_i )
    state <= IDLE_S;
  else
    state <= state_next;

always_comb
  begin
    state_next = state;
    unique case( state )
      IDLE_S             : if( new_request ) state_next = PUSH_TRANSACTION_S;
      PUSH_TRANSACTION_S : if( push_done   ) state_next = WAIT_S;
      WAIT_S             : if( done        ) state_next = read_case ? GET_READDATA_S : DONE_S;
      GET_READDATA_S     : if( rx_empty    ) state_next = DONE_S;
      DONE_S             :                   state_next = IDLE_S;
    endcase
  end

//******************************************************************************
//*************************** MAKE TRANSACTION *********************************
bit_op_t [MAX_TR_OPS-1:0] transaction;

// see i2c_master_pkg.sv
sgtl_write_tr_t sgtl_write_tr;
sgtl_read_tr_t  sgtl_read_tr;
ads_write_tr_t  ads_write_tr;
ads_read_tr_t   ads_read_tr;

// Functions from i2c_core_pkg maps data to operation-specific bit positions
assign sgtl_write_tr = sgtl_write_apply_blueprint( amm_sgtl_if.address, amm_sgtl_if.writedata );
assign sgtl_read_tr  = sgtl_read_apply_blueprint(  amm_sgtl_if.address );
assign ads_write_tr  = ads_write_apply_blueprint(  amm_ads_if.address, amm_ads_if.writedata );
assign ads_read_tr   = ads_read_apply_blueprint(   amm_ads_if.address );

always_ff @( posedge clk_i )
  if( new_request && state==IDLE_S )
    priority case ( 1'b1 )
      ( amm_sgtl_if.write ) : transaction[SGTL_WRITE_OP_CNT-1:0] <= sgtl_write_tr;
      ( amm_sgtl_if.read  ) : transaction[SGTL_READ_OP_CNT -1:0] <= sgtl_read_tr;
      ( amm_ads_if.write  ) : transaction[ADS_WRITE_OP_CNT -1:0] <= ads_write_tr;
      ( amm_ads_if.read   ) : transaction[ADS_READ_OP_CNT  -1:0] <= ads_read_tr;
    endcase
  else
    if( state==PUSH_TRANSACTION_S )
      transaction <= transaction >> $bits(bit_op_t); // shift 1 bit_op right

always_ff @( posedge clk_i )
  if( state!=PUSH_TRANSACTION_S )
    counter <= 1'b0;
  else
    counter <= counter + 1'b1;

always_comb
  unique case ( transaction_case )
    SGTL_WRITE : push_done = ( counter == SGTL_WRITE_OP_CNT - 1 );
    SGTL_READ  : push_done = ( counter == SGTL_READ_OP_CNT  - 1 );
    ADS_WRITE  : push_done = ( counter == ADS_WRITE_OP_CNT  - 1 );
    ADS_READ   : push_done = ( counter == ADS_READ_OP_CNT   - 1 );
  endcase

//******************************************************************************
//********************************** CORE **************************************

bit_operation #(
  .SYS_CLK_FREQ_HZ                        ( SYS_CLK_FREQ_HZ             ),
  .I2C_FREQ_HZ                            ( I2C_FREQ_HZ                 ),
  .MAX_TR_OPS                             ( MAX_TR_OPS                  ),
  .MAX_READ_BITS                          ( MAX_READ_BITS               )
) bit_operation (
  .clk_i                                  ( clk_i                       ),
  .srst_i                                 ( srst_i | state==DONE_S      ),
  .bit_op_i                               ( transaction[0]              ),
  .push_bit_op_i                          ( state==PUSH_TRANSACTION_S   ),

  .rx_bit_o                               ( rx_bit                      ),
  .rx_bit_queue_empty_o                   ( rx_empty                    ),
  .pull_rx_bit_i                          ( state==GET_READDATA_S       ),

  .start_i                                ( push_done                   ),
  .busy_o                                 (                             ),
  .done_o                                 ( done                        ),
  .error_o                                ( error                       ),
  .scl_o                                  ( scl_o                       ),
  .sda_io                                 ( sda_io                      )
);

//******************************************************************************
//*************************** HANDLE READDATA **********************************

logic [MAX_READ_BITS-1:0] readdata_vector;

always_ff @( posedge clk_i )
  if( state==GET_READDATA_S && !rx_empty)
    readdata_vector <= {readdata_vector[MAX_READ_BITS-2:0], rx_bit };

assign amm_sgtl_if.readdata      = error ? 16'hdead : readdata_vector[15:0];
assign amm_sgtl_if.readdatavalid = read_case && sgtl_case && state==DONE_S;
assign amm_sgtl_if.waitrequest   = !( sgtl_case && state==DONE_S );

assign amm_ads_if.readdata      = error ? 8'had : readdata_vector[7:0];
assign amm_ads_if.readdatavalid = read_case && ads_case && state==DONE_S;
assign amm_ads_if.waitrequest   = !( ads_case && state==DONE_S );

endmodule
