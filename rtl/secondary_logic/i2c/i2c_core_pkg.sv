/*
 * MIT License
 *
 * Copyright (c) 2024 Dmitriy Nekrasov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * ---------------------------------------------------------------------------------
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 *
 */

package i2c_core_pkg;

/*
// I want enum, but quartus won't let me have packed array of enums
typedef enum logic [2:0] {
  TX_0,
  TX_1,
  RX,
  RX_ACK,
  RS
} bit_op_t;
*/
typedef logic [2:0] bit_op_t;

parameter logic [2:0] TX_0   = 3'd0;
parameter logic [2:0] TX_1   = 3'd1;
parameter logic [2:0] RX     = 3'd2;
parameter logic [2:0] RX_ACK = 3'd3;
parameter logic [2:0] RS     = 3'd4;

//  0001010 BIG ENDIAN
parameter bit_op_t [6:0] sgtl_5000_i2c_addr = {TX_0, TX_1, TX_0, TX_1, TX_0, TX_0, TX_0 };
// 1001000 BIG ENDIAN
parameter bit_op_t [6:0] ads_7830_i2c_addr = {TX_0, TX_0, TX_0, TX_1, TX_0, TX_0, TX_1 };

typedef struct packed {
  bit_op_t       ack4;
  bit_op_t [7:0] data_byte0;
  bit_op_t       ack3;
  bit_op_t [7:0] data_byte1;
  bit_op_t       ack2;
  bit_op_t [7:0] addr_byte0;
  bit_op_t       ack1;
  bit_op_t [7:0] addr_byte1;
  bit_op_t       ack0;
  bit_op_t       rw_bit;
  bit_op_t [6:0] device_addr;
} sgtl_write_tr_t;

parameter sgtl_write_tr_t sgtl_write_blueprint = '{
  ack0        : RX_ACK,
  ack1        : RX_ACK,
  ack2        : RX_ACK,
  ack3        : RX_ACK,
  ack4        : RX_ACK,
  rw_bit      : TX_0, // 0 for write
  device_addr : sgtl_5000_i2c_addr,
  default     : {8{TX_0}} // data_byte0, data_byte1, addr_byte0, addr_byte1
};

function sgtl_write_tr_t sgtl_write_apply_blueprint( input logic [15:0] address, data );
  int i;
  sgtl_write_tr_t ret;
  ret = sgtl_write_blueprint;
  for( i = 0; i < 8; i++ )
    begin
      ret.addr_byte0[i] = address[7-i]  ? TX_1 : TX_0;
      ret.addr_byte1[i] = address[15-i] ? TX_1 : TX_0;
      ret.data_byte0[i] = data[7-i]     ? TX_1 : TX_0;
      ret.data_byte1[i] = data[15-i]    ? TX_1 : TX_0;
    end
  return ret;
endfunction

//*****************************************************************************

typedef struct packed {
  bit_op_t       nack;
  bit_op_t [7:0] data_byte0;
  bit_op_t       ack4;
  bit_op_t [7:0] data_byte1;
  bit_op_t       ack3;
  bit_op_t       rw_bit1;
  bit_op_t [6:0] device_addr1;
  bit_op_t       restart;
  bit_op_t       ack2;
  bit_op_t [7:0] addr_byte0;
  bit_op_t       ack1;
  bit_op_t [7:0] addr_byte1;
  bit_op_t       ack0;
  bit_op_t       rw_bit0;
  bit_op_t [6:0] device_addr0;
} sgtl_read_tr_t;

parameter sgtl_read_tr_t sgtl_read_blueprint = '{
  ack0         : RX_ACK,
  ack1         : RX_ACK,
  ack2         : RX_ACK,
  ack3         : RX_ACK,
  ack4         : TX_0, // send ACK
  nack         : TX_1,
  rw_bit0      : TX_0, // write
  rw_bit1      : TX_1, // read
  restart      : RS,
  device_addr0 : sgtl_5000_i2c_addr,
  device_addr1 : sgtl_5000_i2c_addr,
  addr_byte0   : {8{TX_0}},
  addr_byte1   : {8{TX_0}},
  data_byte0   : {8{RX}},
  data_byte1   : {8{RX}}
};

function sgtl_read_tr_t sgtl_read_apply_blueprint( input logic [15:0] address );
  int i;
  sgtl_read_tr_t ret;
  ret = sgtl_read_blueprint;
  for( i = 0; i < 8; i++ )
    begin
      ret.addr_byte0[i] = address[7-i]  ? TX_1 : TX_0;
      ret.addr_byte1[i] = address[15-i] ? TX_1 : TX_0;
    end
  return ret;
endfunction

//*****************************************************************************

typedef struct packed {
  bit_op_t       ack1;
  bit_op_t [7:0] cmd_byte;
  bit_op_t       ack0;
  bit_op_t       rw_bit;
  bit_op_t [6:0] device_addr;
} ads_write_tr_t;

parameter ads_write_tr_t ads_write_blueprint = '{
  ack0        : RX_ACK,
  ack1        : RX_ACK,
  rw_bit      : TX_0,
  device_addr : ads_7830_i2c_addr,
  cmd_byte    : {8{TX_0}}
};

function ads_write_tr_t ads_write_apply_blueprint( input logic [2:0] address, logic [1:0] data );
  int i;
  ads_write_tr_t ret;
  ret = ads_write_blueprint;
  ret.cmd_byte[0] = TX_1; // SINGLE ENDED mode hardcode
  ret.cmd_byte[1] = address[2] ? TX_1 : TX_0;
  ret.cmd_byte[2] = address[1] ? TX_1 : TX_0;
  ret.cmd_byte[3] = address[0] ? TX_1 : TX_0;
  ret.cmd_byte[4] = data[1]    ? TX_1 : TX_0;
  ret.cmd_byte[5] = data[0]    ? TX_1 : TX_0;
  return ret;
endfunction
//*****************************************************************************

typedef struct packed {
  bit_op_t       nack;
  bit_op_t [7:0] data_byte;
  bit_op_t       ack2;
  bit_op_t       rw_bit1;
  bit_op_t [6:0] device_addr1;
  bit_op_t       restart;
  bit_op_t       ack1;
  bit_op_t [7:0] cmd_byte;
  bit_op_t       ack0;
  bit_op_t       rw_bit0;
  bit_op_t [6:0] device_addr0;
} ads_read_tr_t;

parameter ads_read_tr_t ads_read_blueprint = '{
  ack0         : RX_ACK,
  ack1         : RX_ACK,
  ack2         : RX_ACK,
  nack         : TX_1,
  rw_bit0      : TX_0,
  rw_bit1      : TX_1,
  restart      : RS,
  device_addr0 : ads_7830_i2c_addr,
  device_addr1 : ads_7830_i2c_addr,
  cmd_byte     : {8{TX_0}},
  data_byte    : {8{RX}}
};

function ads_read_tr_t ads_read_apply_blueprint( input logic [2:0] address );
  int i;
  ads_read_tr_t ret;
  ret = ads_read_blueprint;
  ret.cmd_byte[0] = TX_1; // SINGLE ENDED mode hardcode
  ret.cmd_byte[1] = address[2] ? TX_1 : TX_0;
  ret.cmd_byte[2] = address[1] ? TX_1 : TX_0;
  ret.cmd_byte[3] = address[0] ? TX_1 : TX_0;
  ret.cmd_byte[4] = TX_1; // Internal reference power up hardcode
  ret.cmd_byte[5] = TX_1; // A/D converter power up harncode
  return ret;
endfunction

endpackage
