/*
 * Copyright (C) 2024 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * ---------------------------------------------------------------------------
 *
 * No external drive testbench just to see if everything is connected, no Z,X
 * stuff, no important warnings. Maybe monitor initializing process. See
 * README.md for details
 */

`timescale 1ns/1ns

module tb;

localparam RUN_CYCLES = 1_000_000;

bit clk_12m;
initial forever #100000 clk_12m = ~clk_12m;

initial
  begin : main
    repeat( RUN_CYCLES ) @( posedge clk_12m );
    $stop;
  end

top DUT (
  .clk_12m_i                ( clk_12m                     ),
  .i2s_mclk_o               (                             ),
  .i2s_bclk_o               (                             ),
  .i2s_lrclk_o              (                             ),
  .i2s_din_o                (                             ),
  .i2s_dout_i               ( 1'b0                        ),
  .pcm1808_fmt_o            (                             ),
  .pcm1808_sf0_o            (                             ),
  .pcm1808_sf1_o            (                             ),
  .i2c_scl_o                (                             ),
  .i2c_sda_io               (                             ),
  .spdif_o                  (                             ),
  .cyc1000_button_i         ( 1'b0                        ),
  .sw_i                     ( 3'd0                        ),
  .cyc1000_led_o            (                             ),
  .user_led_o               (                             ),
  .relay_o                  (                             ),
  .D11_R                    (                             ),
  .D12_R                    (                             ),
  .dac_mute_o               (                             ),
  .a_o                      (                             ),
  .bs_o                     (                             ),
  .dq_io                    (                             ),
  .dqm_o                    (                             ),
  .cs_o                     (                             ),
  .ras_o                    (                             ),
  .cas_o                    (                             ),
  .we_o                     (                             ),
  .cke_o                    (                             ),
  .sdram_clk_o              (                             )
);


endmodule
