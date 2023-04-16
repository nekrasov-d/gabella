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

`timescale 1ns/1ns

`include "mailbox_demux.sv"

module tb;

bit clk;
bit srst;

bit i2s_sclk;
bit i2s_lrclk;
bit i2s_data_in;
bit i2s_data_out;

initial
  begin
    clk = 0;
    forever #5 clk = ~clk;
  end

initial
  begin
    srst     = 0;
    #5 srst  = 1;
    #15 srst = 0;
  end

default clocking cb @( posedge clk );
endclocking

event clk_ev;
always @( posedge clk ) -> clk_ev;

//*****************************************************************************
//*****************************************************************************
avalon_st_if #(.DATA_WIDTH(16)) sample_in  ();
avalon_st_if #(.DATA_WIDTH(16)) sample_out ();

mailbox tx_data_mbx;
mailbox _tx_data_mbx;
mailbox rx_data_mbx;
mailbox ref_data_mbx;

typedef logic [15:0] data_t;

MailboxDemux #(.MSG_TYPE ( data_t ), .OUTPUTS_CNT ( 2 ) ) mailbox_demux;

task automatic i2s_driver( );
  int i, j;
  bit [15:0] tx_data, rx_data;
  fork
    forever
      begin
        repeat (576) @( posedge clk );
        i2s_sclk = ~i2s_sclk;
      end
    forever
      begin
        repeat (16) @( negedge i2s_sclk );
        i2s_lrclk = ~i2s_lrclk;
      end
    forever
      begin
        // wait for left channel
        @( negedge i2s_lrclk );
        #1;
        if( tx_data_mbx.num() > 0 )
          begin
          tx_data_mbx.get( tx_data );
          $display("getting data\n");
          end
        else
          tx_data = '0;
        i2s_data_out = tx_data[15];
        for( i = 0; i < 15; i++ )
          @( negedge i2s_sclk ) i2s_data_out = tx_data[14-i];

        @( negedge i2s_sclk );
        i2s_data_out = 0;
      end
    forever
      begin
        // wait for left channel
        @( negedge i2s_lrclk );
        #1;
        rx_data = '0;
        for( j = 0; j < 16; j++ )
          @( posedge i2s_sclk ) rx_data[15-j] = i2s_data_in;
        if( rx_data != 0 )
          rx_data_mbx.put( rx_data );
      end
  join_none
endtask

task automatic i2s_monitor();
  logic [15:0] data, ref_data;
  fork
    forever
      begin
        @( posedge clk );
        if( rx_data_mbx.num() > 0 )
          begin
            rx_data_mbx.get( data );
            ref_data_mbx.get( ref_data );
            if( data != ref_data )
              $error("Error: rx data and ref data different/n");
            else
              $display("Data OK, value = %4h\n", data);
          end // compare
      end // forever loop
  join_none
endtask


initial
  begin : main
    tx_data_mbx   = new();
    _tx_data_mbx  = new();
    rx_data_mbx   = new();
    ref_data_mbx  = new();
    //mailbox_demux = new( tx_data_mbx, '{_tx_data_mbx, ref_data_mbx}, clk_ev );
    //mailbox_demux.run();
    ##10;
    $display("*************************************************************/n/n");
    i2s_driver();
    //i2s_monitor();
    //*********************************
    tx_data_mbx.put( 16'hc5c5 );

    ##1000000;
    $stop;
  end


i2s_core #(
  .DATA_WIDTH                             ( 16                          ),
  .BUFFERS_AWIDTH                         ( 8                           ),
  .LEFT_CHANNEL_EN                        ( 1                           ),
  .RIGHT_CHANNEL_EN                       ( 0                           )
) dut (
  .clk_i                                  ( clk                         ),
  .srst_i                                 ( srst                        ),
  .i2s_sclk_i                             ( i2s_sclk                    ),
  .i2s_lrclk_i                            ( i2s_lrclk                   ),
  .i2s_data_i                             ( i2s_data_out                ),
  .i2s_data_o                             ( i2s_data_in                 ),
  .sample_in                              ( sample_in                   ),
  .sample_out                             ( sample_out                  )
);

assign sample_out.data  = sample_in.data;
assign sample_out.valid = sample_in.valid;

endmodule
