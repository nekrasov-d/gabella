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

// Left justified data format

module i2s_core #(
  parameter               DATA_WIDTH             = 16,
  parameter               BUFFERS_AWIDTH         = 4,
  parameter               LEFT_CHANNEL_EN        = 1,
  parameter               RIGHT_CHANNEL_EN       = 0,
  parameter               DIN_DOUT_SHORTCUT      = 0
) (
  input                   clk_i,
  input                   srst_i,
  input                   din_dout_shortcut_i,

  input                   i2s_sclk_i,
  input                   i2s_lrclk_i,
  input                   i2s_data_i,
  output logic            i2s_data_o,

  input [23:0]            left_data_i,
  input                   left_data_val_i,
  output logic [23:0]     left_data_o,
  output logic            left_data_val_o
);

enum logic { RIGHT_S, LEFT_S } state, state_next;

logic i2s_data_out_left;
logic i2s_data_out_right;

logic sclk_posedge;
logic sclk_negedge;

logic [1:0] sclk_d;
logic [4:0] lrclk_d;

always_ff @( posedge clk_i )
  begin
    sclk_d  <= {sclk_d[0],    i2s_sclk_i};
    lrclk_d <= {lrclk_d[3:0], i2s_lrclk_i};
  end

assign sclk_posedge =  sclk_d[0] && !sclk_d[1];
assign sclk_negedge = !sclk_d[0] &&  sclk_d[1];

always_ff @( posedge clk_i )
  if( srst_i )
    state <= LEFT_S;
  else
    state <= state_next;

always_comb
  begin
    state_next = state;
    case( state )
      LEFT_S  : if(  lrclk_d[1] && !lrclk_d[2] ) state_next = RIGHT_S;
      RIGHT_S : if( !lrclk_d[1] &&  lrclk_d[2] ) state_next = LEFT_S;
    endcase
  end

logic state_change;
assign state_change = state != state_next;

//********************************************************************
//*******************************************************************

logic [31:0] tmp_left_in/* synthesis keep */;
logic [31:0] tmp_left_out/* synthesis keep */;

generate
  if( LEFT_CHANNEL_EN )
    begin : gen_left_channel

      logic [31:0] tmp_in/* synthesis keep */;
      logic [31:0] tmp_out/* synthesis keep */;

      assign tmp_in = left_data_i[23] ? { left_data_i, 8'hff } :
                                        { left_data_i, 8'h00 } ;

      i2s_channel #(
        .I2S_FORMAT                  ( 1                              ),
        .DATA_WIDTH                  ( 32                             ),
        .BUFFERS_AWIDTH              ( BUFFERS_AWIDTH                 )
      ) left_channel (
        .clk_i                       ( clk_i                          ),
        .srst_i                      ( srst_i                         ),
        .word_end_i                  ( state==LEFT_S && state_change  ),
        .i2s_clk_posedge_i           ( sclk_posedge && state==LEFT_S  ),
        .i2s_clk_negedge_i           ( sclk_negedge && state==LEFT_S  ),
        .i2s_data_i                  ( i2s_data_i                     ),
        .i2s_data_o                  ( i2s_data_out_left              ),
        .data_i                      ( tmp_in                         ),
        .data_val_i                  ( left_data_val_i                ),
        .data_o                      ( tmp_out                        ),
        .data_val_o                  ( left_data_val_o                )
      );

      assign left_data_o = tmp_out[31:8];

    end // gen_left_channel
endgenerate


/*
generate
  if( RIGHT_CHANNEL_EN )
    begin : gen_right_channel
      i2s_channel #(
        .DATA_WIDTH                  ( DATA_WIDTH                     ),
        .BUFFERS_AWIDTH              ( BUFFERS_AWIDTH                 )
      ) right_channel (
        .clk_i                       ( clk_i                          ),
        .srst_i                      ( srst_i                         ),
        .word_start_i                ( right_word_start               ),
        .i2s_clk_posedge_i           ( sclk_posedge && state==RIGHT_S ),
        .i2s_clk_negedge_i           ( sclk_negedge && state==RIGHT_S ),
        .i2s_data_i                  ( i2s_data_i                     ),
        .i2s_data_o                  ( i2s_data_out_right             ),
        .data_i                      ( right_out.data                 ),
        .data_val_i                  ( right_out.valid                ),
        .data_o                      ( right_in.data                  ),
        .data_val_o                  ( right_in.valid                 )
      );
      // always ready
      assign right_out.ready = 1'b1;
    end // gen_right_channel
endgenerate
*/

always_comb
  case( i2s_lrclk_i )
    1'b0  : i2s_data_o = din_dout_shortcut_i ? i2s_data_i : i2s_data_out_left;
    1'b1  : i2s_data_o = i2s_data_i;
  endcase


endmodule
