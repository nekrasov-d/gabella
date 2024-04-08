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

module ads_i2c_routine #(
  parameter ROBOT_READ_EN      = 1,
  parameter SYS_CLK_FREQ_HZ    = 25000000,
  parameter ROBOT_READ_FREQ_HZ = 100
  )(
  input                   clk_i,
  input                   srst_i,
  avalon_mm_if            ads_if,
  output logic [7:0][7:0] knob_level_o
);
// See TABLE 2 in ADS7830 documentation
logic [7:0][7:0] knob_level;
logic [7:0][7:0] knob_level_remap;

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
