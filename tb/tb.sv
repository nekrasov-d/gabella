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
 * No external drive testbench just to see if everything is connected, no Z,X
 * stuff, no important warnings. Maybe monitor initializing process. See
 * README.md for details
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 *
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
