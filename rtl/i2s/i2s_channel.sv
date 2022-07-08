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

module i2s_channel #(
  parameter                     I2S_FORMAT     = 1,
  parameter                     DATA_WIDTH     = 16,
  parameter                     BUFFERS_AWIDTH = 8
) (
  input                         clk_i,
  input                         srst_i,

  input                         word_end_i,
  input                         i2s_clk_posedge_i,
  input                         i2s_clk_negedge_i,
  input                         i2s_data_i,
  output logic                  i2s_data_o,

  input        [DATA_WIDTH-1:0] data_i,
  input                         data_val_i,
  output logic [DATA_WIDTH-1:0] data_o,
  output logic                  data_val_o
);


//*****************************************************************************
//********************************** INPUT ************************************
logic [DATA_WIDTH-1:0]       input_reg;
logic [$clog2(DATA_WIDTH):0] posedge_cnt;

always_ff @( posedge clk_i )
  if( srst_i || word_end_i )
    posedge_cnt <= '0;
  else
    if( i2s_clk_posedge_i )
      posedge_cnt <= posedge_cnt + 1'b1;

always_ff @( posedge clk_i )
  for( int i = 0; i < DATA_WIDTH; i++ )
    if( i2s_clk_posedge_i && posedge_cnt ==i )
      input_reg[DATA_WIDTH-1-i] <= i2s_data_i;

//assign data_o  = I2S_FORMAT ? input_reg << 1 : input_reg;

always_ff @( posedge clk_i )
  if( word_end_i )
    data_o <= I2S_FORMAT ? input_reg << 1 : input_reg;

always_ff @( posedge clk_i )
  data_val_o <= word_end_i;

//*****************************************************************************
//********************************* OUTPUT ************************************

logic [DATA_WIDTH-1:0]       output_reg;
logic [DATA_WIDTH-1:0]       output_reg_revert;
logic [$clog2(DATA_WIDTH):0] negedge_cnt;

always_ff @( posedge clk_i )
  if( srst_i || word_end_i )
    negedge_cnt <= 1'b0;
  else
    if( i2s_clk_negedge_i )
      negedge_cnt <= negedge_cnt + 1'b1;

always_ff @( posedge clk_i )
  if( srst_i )
    output_reg <= '0;
  else
    if( data_val_i )
      output_reg <= I2S_FORMAT ? data_i >> 1 : data_i;

always_comb
  for( int i = 0; i < DATA_WIDTH; i++ )
    output_reg_revert[i] = output_reg[DATA_WIDTH-1-i];

always_ff @( posedge clk_i )
  i2s_data_o <= output_reg_revert[negedge_cnt];

endmodule
