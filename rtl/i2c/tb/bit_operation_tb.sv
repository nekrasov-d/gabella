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
import i2c_master_pkg::*;

module tb;

parameter SYS_CLK_FREQ = 25000000;
parameter I2C_FREQ     = 100000;
parameter bit [6:0] SGTL5000_I2C_ADDRESS = 7'b1110101;
parameter bit [6:0] ADS7830_I2C_ADDRESS  = ~7'b1110101;


bit        clk;
bit        srst;
bit        scl;
wire       sda;

bit_op_t bit_op;
bit      push_bit_op;
bit      rx_bit;
bit      rx_bit_queue_empty;
bit      pull_rx_bit;
bit      start;
bit      busy;
bit      done;
bit      error;

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

//*****************************************************************************
//*****************************************************************************

struct packed {
  bit_op_t       ack4;
  bit_op_t [7:0] data_byte0;
  bit_op_t       ack3;
  bit_op_t [7:0] data_byte1;
  bit_op_t       ack2;
  bit_op_t [7:0] addr_byte0;
  bit_op_t       ack1;
  bit_op_t [7:0] addr_byte1;
  bit_op_t       ack0;
  bit_op_t       rw;
  bit_op_t [6:0] device_addr;
} sgtl5000_write, sgtl5000_read;


struct packed {
  bit_op_t       nack;
  bit_op_t [7:0] data;
  bit_op_t       ack2;
  bit_op_t       read;
  bit_op_t [6:0] device_addr1;
  bit_op_t       restart;
  bit_op_t       ack1;
  bit_op_t [7:0] cmd_byte;
  bit_op_t       ack0;
  bit_op_t       write;
  bit_op_t [6:0] device_addr0;
} ads_read;


bit [$bits(sgtl5000_write)-1:0][2:0] array1, array2;

bit [$bits(ads_read)-1:0][2:0] array3;

assign array1 = sgtl5000_write;
assign array2 = sgtl5000_read;
assign array3 = ads_read;


initial
  begin
    int i;
    for( i = 0; i < 7; i++ )
      begin
        ads_read.device_addr0[i].data    = ADS7830_I2C_ADDRESS[i];
        ads_read.device_addr1[i].data    = ADS7830_I2C_ADDRESS[i];
        ads_read.device_addr0[i].control = SEND;
        ads_read.device_addr1[i].control = SEND;
      end

    for( i = 0; i < 8; i++ )
      begin
        ads_read.cmd_byte[i].control = SEND;
        ads_read.data[i].control     = RECEIVE;
      end

    ads_read.write.data    = 0; // 0 for write
    ads_read.write.control = SEND; // 0 for write

    ads_read.ack0.data    = 0;           // don't care actually
    ads_read.ack0.control = RECEIVE_ACK;

    ads_read.ack1.data    = 0;           // don't care actually
    ads_read.ack1.control = RECEIVE_ACK;

    ads_read.restart.data   = 0;           // don't care actually
    ads_read.restart.control = RESTART;

    ads_read.read.data    = 1; // 0 for write
    ads_read.read.control = SEND; // 0 for write

    ads_read.ack2.data    = 0;           // don't care actually
    ads_read.ack2.control = RECEIVE_ACK;

    ads_read.nack.data    = 1;           // send NACK
    ads_read.nack.control = SEND;
  end




initial
  begin
    int i;
    for( i = 0; i < 7; i++ )
      begin
        sgtl5000_read.device_addr[i].data    = SGTL5000_I2C_ADDRESS[i];
        sgtl5000_read.device_addr[i].control = SEND;
      end

    for( i = 0; i < 8; i++ )
      begin
        sgtl5000_read.data_byte0[i].control = RECEIVE;
        sgtl5000_read.data_byte1[i].control = RECEIVE;
        sgtl5000_read.addr_byte0[i].control = SEND;
        sgtl5000_read.addr_byte1[i].control = SEND;
      end

    sgtl5000_read.rw.data    = 0; // 0 for write
    sgtl5000_read.rw.control = SEND; // 0 for write

    sgtl5000_read.ack0.data    = 0;           // don't care actually
    sgtl5000_read.ack0.control = RECEIVE_ACK;

    sgtl5000_read.ack1.data    = 0;           // don't care actually
    sgtl5000_read.ack1.control = RECEIVE_ACK;

    sgtl5000_read.ack2.data    = 0;           // don't care actually
    sgtl5000_read.ack2.control = RECEIVE_ACK;

    sgtl5000_read.ack3.data    = 0;           // send ACK
    sgtl5000_read.ack3.control = SEND;

    sgtl5000_read.ack4.data    = 1;           // send NACK (!)
    sgtl5000_read.ack4.control = SEND;
  end

initial
  begin
    int i;
    for( i = 0; i < 7; i++ )
      begin
        sgtl5000_write.device_addr[i].data    = SGTL5000_I2C_ADDRESS[i];
        sgtl5000_write.device_addr[i].control = SEND;
      end

    for( i = 0; i < 8; i++ )
      begin
        sgtl5000_write.data_byte0[i].control = SEND;
        sgtl5000_write.data_byte1[i].control = SEND;
        sgtl5000_write.addr_byte0[i].control = SEND;
        sgtl5000_write.addr_byte1[i].control = SEND;
      end

    sgtl5000_write.rw.data    = 1; // 1 for read
    sgtl5000_write.rw.control = SEND;

    sgtl5000_write.ack0.data    = 0;           // don't care actually
    sgtl5000_write.ack0.control = RECEIVE_ACK;

    sgtl5000_write.ack1.data    = 0;           // don't care actually
    sgtl5000_write.ack1.control = RECEIVE_ACK;

    sgtl5000_write.ack2.data    = 0;           // don't care actually
    sgtl5000_write.ack2.control = RECEIVE_ACK;

    sgtl5000_write.ack3.data    = 0;           // don't care actually
    sgtl5000_write.ack3.control = RECEIVE_ACK;

    sgtl5000_write.ack4.data    = 0;           // don't care actually
    sgtl5000_write.ack4.control = RECEIVE_ACK;
  end

initial
  begin : main
    bit [15:0] address;
    bit [15:0] data;
    int i;

    data = 16'haaaa;
    address = 16'h3333;

    for( i = 0; i < 8; i++ )
      begin
        sgtl5000_write.data_byte0[i].data = data[i];
        sgtl5000_write.data_byte1[i].data = data[i+8];
        sgtl5000_write.addr_byte0[i].data = address[i];
        sgtl5000_write.addr_byte1[i].data = address[i+8];
      end

    //repeat (1000) @( posedge clk );

    repeat (10) @( posedge clk );

    //for( i = 0; i < $bits(sgtl5000_write); i++ )
    for( i = 0; i < 45; i++ )
      begin
        bit_op      = array1[i];
        push_bit_op = 1;
        @( posedge clk );
      end
    push_bit_op = 0;
    start = 1;
    @( posedge clk );
    start = 0;

    wait( done );

    repeat (1000) @( posedge clk );

    for( i = 0; i < 45; i++ )
      begin
        bit_op      = array1[i];
        push_bit_op = 1;
        @( posedge clk );
      end
    push_bit_op = 0;
    start = 1;
    @( posedge clk );
    start = 0;

    wait( done );

    repeat (1000) @( posedge clk );

    for( i = 0; i < 45; i++ )
      begin
        bit_op      = array2[i];
        push_bit_op = 1;
        @( posedge clk );
      end
    push_bit_op = 0;
    start = 1;
    @( posedge clk );
    start = 0;

    wait( done );

    repeat (1000) @( posedge clk );

    while( !rx_bit_queue_empty )
      begin
        pull_rx_bit = 1;
        @( posedge clk );
      end

    pull_rx_bit = 0;

    repeat (1000) @( posedge clk );

    for( i = 0; i < 37; i++ )
      begin
        bit_op      = array3[i];
        push_bit_op = 1;
        @( posedge clk );
      end
    push_bit_op = 0;
    start = 1;
    @( posedge clk );
    start = 0;
    wait( done );
    repeat (1000) @( posedge clk );
    $stop;
  end

bit_operation #(
  .SYS_CLK_FREQ                           ( SYS_CLK_FREQ                ),
  .I2C_FREQ                               ( I2C_FREQ                    )
) bit_operation (
  .clk_i                                  ( clk                         ),
  .srst_i                                 ( srst                        ),
  .bit_op_i                               ( bit_op                      ),
  .push_bit_op_i                          ( push_bit_op                 ),
  .rx_bit_o                               ( rx_bit                      ),
  .rx_bit_queue_empty_o                   ( rx_bit_queue_empty          ),
  .pull_rx_bit_i                          ( pull_rx_bit                 ),
  .start_i                                ( start                       ),
  .busy_o                                 ( busy                        ),
  .done_o                                 ( done                        ),
  .error_o                                ( error                       ),
  .scl_o                                  ( scl                         ),
  .sda_io                                 ( sda                         )
);


endmodule
