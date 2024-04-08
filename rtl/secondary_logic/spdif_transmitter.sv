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
 * Simple spdif mono transmitter hardcoded for and 44100 samples per second
 * audio data rate. Utilizes four 11.2896 MHz clock cycles to transmit one bit
 * of data. valid_i strobe should arrive at 44100 Hz frequency. But whatever the
 * actual data rate, this module locks and transmits data 44100 times per second
 * (based on 11.2896 spdif_clk_i which is actually i2s MCLK clock speed).
 *
 * Having audio stream in your system it's likely thay you also have i2s mclk
 * running, and 44100 sample valid pulse is also based on this clock. It's apt
 * to use this clock as spdif_clk_i
 *
 * Interface:
 *   - sys_clk_i   : system clock data_i and valid_i are synced to. Must have higher
 *                   than spdif_clk_i frequency. Tested with 25.0 MHz sys clk,
 *                   if you change it make sure to validate spdif_strobe_cdc
 *                   RATIO parameter
 *
 *   - spdif_clk_i : 11.2896 MHz
 *
 *   - data_i      : Audio samle, signed integer. 16 or 24 bit
 *                   Stable at least few (depends on clock relationship) cycles
 *                   after valid_i
 *
 *   - valid_i     : Strobe that activates frame sending. Should appear only once for
 *                   one symbol
 *
 *   - spdif_o     : you won't believe...
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Sat, 09 Mar 2024 11:39:19 +0300
 */


module spdif_transmitter #(
  parameter DATA_WIDTH = 16 // 16 or 24
) (
  input                  sys_clk_i, // data_i and valid_i are synced to this one
  input                  sys_srst_i,
  input                  spdif_clk_i,
  input [DATA_WIDTH-1:0] data_i,
  input                  valid_i,
  output logic           spdif_o
);

// Readability aliases
localparam [0:0] LEFT  = 0;
localparam [0:0] RIGHT = 1;

//**********************************************************************************
// Regs and wires

// Synced to spdif_clk_i
logic valid;
logic srst;

// The thing we're going to send
logic [27:0] frame;

// subcode, channel status and validity are going to be kept 0 (0 = valid)
// so they won't affect parity, use only data to calcualate it
// we need only 0th bit, but synthesizer will discard redundant logic anyway
logic [4:0] data_bit_population;

logic [23:0] data; // == data_i if DATA_WIDTH==24, else data_i + zero padding

logic subcode, channel_status, validity, parity; // Other frame content

enum logic [1:0] {
  IDLE_S,
  PREAMBLE_S,
  DATA_S,
  PAD_S
} state, state_next;

// Aux wires to simplify conditional branching expressions
logic change_state;
logic change_bit;
logic data_end;

// There are two counters. Bit counter counts through frame bits,
// intrabit counter counts those 8 subdivsions inside one bit
// let's name the last one just 'cnt'
// (or 32 inside preamble).
logic [4:0] bit_cnt;
logic [3:0] cnt;

logic channel;    // Flips after a subframe has been sent
logic last_level; // Select proper pattern if we change state or change bit

// It needs to count to 192, so 8 bit is enough
logic [7:0] frame_cnt;
logic       new_block;

// Transmission patterns. They act like constants, so I typed them in uppercase
logic [3:0]  ONE;
logic [3:0]  ZERO;
// Strandard names
logic [15:0] PREAMBLE_X;
logic [15:0] PREAMBLE_Y;
logic [15:0] PREAMBLE_Z;
// assigned to channels
logic [15:0] PREAMBLE_L;
logic [15:0] PREAMBLE_R;

//**********************************************************************************
// Set transmission patterns

assign ONE        = last_level ? 4'b1100 : 4'b0011;
assign ZERO       = last_level ? 4'b0000 : 4'b1111;
assign PREAMBLE_X = last_level ? 16'b_1100_1111_1100_0000 : 16'b_0011_0000_0011_1111;
assign PREAMBLE_Y = last_level ? 16'b_1111_0011_1100_0000 : 16'b_0000_1100_0011_1111;
assign PREAMBLE_Z = last_level ? 16'b_1111_1100_1100_0000 : 16'b_0000_0011_0011_1111;

assign PREAMBLE_L = new_block ? PREAMBLE_Z : PREAMBLE_X;
assign PREAMBLE_R = PREAMBLE_Y;

//**********************************************************************************
// CDC

// In this section we utilize the fact that valid_i, despite being transmitted
// on a higher frequency, is rare. After it has been set, data_i remains stable
// at least ceil( Fsys / Fsdpif ) sys_clk_i cycles so there is enough time to
// pass valid_i into spdif clk domain and register this data.
spdif_strobe_cdc srst_cdc  ( sys_clk_i, spdif_clk_i, sys_srst_i, srst  );
spdif_strobe_cdc valid_cdc ( sys_clk_i, spdif_clk_i, valid_i,    valid );

always_ff @( posedge spdif_clk_i )
  if( valid )
    data <= DATA_WIDTH==24 ? data_i : { data_i, 8'h00 };

//***********************************************************************************
// Prepare subframe (aka just frame...)

always_comb
  begin
    data_bit_population = 0;
    for( int i = 0; i < $bits(data); i++ )
      data_bit_population += data[i];
  end

assign { subcode, channel_status, validity } = 3'b000; // 0 = valid
assign parity = data_bit_population[0];

always_ff @( posedge spdif_clk_i )
  if( state!=PREAMBLE_S && state_next==PREAMBLE_S && channel==1'b0 )
    frame <= { parity, channel_status, subcode, validity, data };

//**********************************************************************************
// FSM + FSM-driven counters

always_ff @( posedge spdif_clk_i )
  state <= srst ? IDLE_S : state_next;

always_comb
  begin
    state_next = state;
    case( state )
      IDLE_S     : if( valid    ) state_next = PREAMBLE_S;
      PREAMBLE_S : if( cnt==15  ) state_next = DATA_S;
      DATA_S     : if( data_end ) state_next = PREAMBLE_S;
      default    :;
    endcase
  end

assign change_state = state != state_next;
assign change_bit   = state_next==DATA_S && cnt==3;
assign data_end     = cnt==3 && bit_cnt==27;

always_ff @( posedge spdif_clk_i )
  if( srst || change_state )
    bit_cnt <= '0;
  else
    if( change_bit )
      bit_cnt <= bit_cnt + 1'b1;

always_ff @( posedge spdif_clk_i )
  cnt <= ( srst || change_state || change_bit ) ? '0 : cnt + 1'b1;

always_ff @( posedge spdif_clk_i )
  if( change_state || change_bit )
    last_level <= spdif_o;

always_ff @( posedge spdif_clk_i )
  if( srst )
    channel <= LEFT;
  else
    if( state==PREAMBLE_S && state_next==DATA_S )
      channel <= ~channel;

always_ff @( posedge spdif_clk_i )
  if( srst )
    frame_cnt <= 8'b0;
  else
    if( state==DATA_S && state_next!=DATA_S && channel )
      frame_cnt <= frame_cnt + 1'b1;
    else
      // Clear if we already used new_block signal to select PREAMBLE_Z
      if( state_next==DATA_S && frame_cnt==8'd192 )
        frame_cnt <= 8'b0;

assign new_block = ( frame_cnt == 8'd0 );

always_comb
  case( state )
    PREAMBLE_S : spdif_o = channel        ? PREAMBLE_R[cnt] : PREAMBLE_L[cnt];
    DATA_S     : spdif_o = frame[bit_cnt] ? ONE[cnt]        : ZERO[cnt];
    default    : spdif_o = 1'b0;
  endcase

endmodule
