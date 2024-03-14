/*
 * Copyright (C) 2024 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

module i2s_transmitter #(
  parameter DATA_WIDTH = 16,
  parameter I2S_FORMAT = "True" // i2s format for i2s bus. If True, spdif still runs
)(
  i2s_if                 i2s,
  input                  clk_i,
  input                  srst_i,
  input                  din_dout_shortcut_i,
  input [DATA_WIDTH-1:0] data_i,
  input                  data_val_i
);

enum logic { RIGHT_S, LEFT_S } state, state_next;

logic sclk_negedge;
logic i2s_clk_negedge;
logic word_end;
logic [1:0] sclk_d;
logic [2:0] lrclk_d;

always_ff @( posedge clk_i )
  begin
    sclk_d  <= {   sclk_d[0],  i2s.bclk  };
    lrclk_d <= { lrclk_d[1:0], i2s.lrclk };
  end

always_ff @( posedge clk_i )
  state <= srst_i ? LEFT_S : state_next;

always_comb
  begin
    state_next = state;
    case( state )
      LEFT_S  : if( lrclk_d[2:1] == 2'b01 ) state_next = RIGHT_S;
      RIGHT_S : if( lrclk_d[2:1] == 2'b10 ) state_next = LEFT_S;
    endcase
  end

assign sclk_negedge    = ( sclk_d == 2'b10 );
assign i2s_clk_negedge = sclk_negedge  && state==LEFT_S;
assign word_end        = state==LEFT_S && state_next==RIGHT_S;

logic [31:0]         output_reg;
logic [31:0]         output_reg_revert;
logic [$clog2(32):0] negedge_cnt;

always_ff @( posedge clk_i )
  if( srst_i || word_end )
    negedge_cnt <= 1'b0;
  else
    if( i2s_clk_negedge )
      negedge_cnt <= negedge_cnt + 1'b1;

always_ff @( posedge clk_i )
  if( data_val_i )
    output_reg <= I2S_FORMAT=="True" ? {data_i, {(32-DATA_WIDTH){1'b0}}} >> 1 :
                                       {data_i, {(32-DATA_WIDTH){1'b0}}};

always_comb
  for( int i = 0; i < 32; i++ )
    output_reg_revert[i] = output_reg[31-i];

always_ff @( posedge clk_i )
  i2s.data_to_dac <= din_dout_shortcut_i ? i2s.data_from_adc : output_reg_revert[negedge_cnt];

endmodule
