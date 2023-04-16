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

module i2s_devices_ctrl (
  input        clk_i, // ( Fs * 256 ), ~= 11_290_332 Hz
  input        srst_i,
  output logic bclk_o,
  output logic lrclk_o,
  output logic devices_ready_o,
  output logic pcm1808_fmt_o,
  output logic pcm1808_sf0_o,
  output logic pcm1808_sf1_o
);

// BCLK = LRCLK * 64 = (MCLK / 256) * 64 = MCLK / 4
logic [1:0] bclk_counter;
logic       bclk_d;
logic       bclk_negedge;

// LRCLK = MCLK / 256
logic [7:0] lrclk_counter;

always @( posedge clk_i )
  if( srst_i )
    bclk_counter <= '0;
  else
    bclk_counter <= bclk_counter + 1'b1;

always_ff @( posedge clk_i )
  bclk_o <= bclk_counter[1];

always @( posedge clk_i )
  if( srst_i )
    lrclk_counter <= '0;
  else
    lrclk_counter <= lrclk_counter + 1'b1;

always_ff @( posedge clk_i )
  lrclk_o <= lrclk_counter[7];

//**************************************************************************

// 1024 mclk cycles
logic [9:0]  pcm1808_reset_counter;
// ( 8960 / Fsample ) seconds ~= 2**22 mclk cycles
logic [21:0] pcm1808_dout_val_counter;

logic ready_flag_0;
logic ready_flag_1;

always_ff @( posedge clk_i )
  if( srst_i )
    pcm1808_reset_counter <= '0;
  else
    pcm1808_reset_counter <= pcm1808_reset_counter + 1'b1;

always_ff @( posedge clk_i )
  if( srst_i )
    pcm1808_dout_val_counter <= '0;
  else
    if( ready_flag_0 )
      pcm1808_dout_val_counter <= pcm1808_dout_val_counter + 1'b1;

always_ff @( posedge clk_i )
  if( srst_i )
    ready_flag_0 <= 0;
  else
    if( pcm1808_reset_counter == '1 )
      ready_flag_0 <= 1'b1;

always_ff @( posedge clk_i )
  if( srst_i )
    ready_flag_1 <= 0;
  else
    if( pcm1808_dout_val_counter == '1 )
      ready_flag_1 <= 1'b1;

always_ff @( posedge clk_i )
  devices_ready_o <= ready_flag_0 && ready_flag_1;

assign pcm1808_fmt_o = 1'b0;
assign pcm1808_sf0_o = 1'b0;
assign pcm1808_sf1_o = 1'b0;

endmodule



