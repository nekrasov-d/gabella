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

module top(
  input               clk_12m_i,
  output logic        i2s_mclk_o,
  output logic        i2s_bclk_o,
  output logic        i2s_lrclk_o,
  output logic        i2s_din_o,
  input               i2s_dout_i,
  output logic        pcm1808_fmt_o,
  output logic        pcm1808_sf0_o,
  output logic        pcm1808_sf1_o,
  output logic        i2c_scl_o,
  inout  wire         i2c_sda_io,
  output logic        spdif_o,
  input               cyc1000_button_i,
  input        [3:1]  sw_i,
  output logic [7:0]  cyc1000_led_o,
  output logic [4:1]  user_led_o,
  output logic        relay_o,
  output logic        D11_R,
  output logic        D12_R,
  output logic        dac_mute_o,
  // SDRAM pins
  output logic [13:0] a_o,
  output logic [1:0]  bs_o,
  inout  wire  [15:0] dq_io,
  output logic [1:0]  dqm_o,
  output logic        cs_o,
  output logic        ras_o,
  output logic        cas_o,
  output logic        we_o,
  output logic        cke_o,
  output logic        sdram_clk_o
);
// Constant drive
//assign D11_R = 1'bz;
//assign D12_R = 1'bz;
assign dac_mute_o = 1'b1;

i2s_if i2s ();
assign
 { i2s_mclk_o, i2s_bclk_o, i2s_lrclk_o, i2s_din_o,       i2s.data_from_adc } =
 { i2s.mclk,     i2s.bclk,   i2s.lrclk, i2s.data_to_dac, i2s_dout_i        };

// PCB SDRAM interface
sdram_if sdram ();
assign dq_io      = sdram.dq_oe ? sdram.dq_o : {16{1'bz}};
assign sdram.dq_i = dq_io;
assign
  {     a_o,     bs_o,     dqm_o,     cs_o,     ras_o,     cas_o,     we_o,     cke_o, sdram_clk_o } =
  { sdram.a, sdram.bs, sdram.dqm, sdram.cs, sdram.ras, sdram.cas, sdram.we, sdram.cke, sdram.clk };

// Interface to communicate with SDRAM driver from application side
external_memory_if #(
  .DATA_WIDTH ( main_config::DATA_WIDTH     ),
  .ADDR_WIDTH ( main_config::MEM_ADDR_WIDTH )
) mem_if [main_config::NUM_MEMORY_INTERFACES-1:0] ();

logic sample_tick /* synthesis noprune */;
logic sys_clk;
logic sys_srst;
logic [2:0] switches;
logic subsystems_ready;
logic cyc1000_button_stb;

// Clocks, resets, other auxiliary things that don't directly related to audio
design_sybsystems design_subsystems(
  .i2s                  ( i2s                         ),
  .sdram                ( sdram                       ),
  .mem_if               ( mem_if                      ),
  .clk_12m_i            ( clk_12m_i                   ),
  .cyc1000_button_i     ( cyc1000_button_i            ),
  .sample_tick_i        ( sample_tick                 ),
  .sw_i                 ( sw_i                        ),
  .sys_clk_o            ( sys_clk                     ),
  .sys_srst_o           ( sys_srst                    ),
  .pcm1808_fmt_o        ( pcm1808_fmt_o               ),
  .pcm1808_sf0_o        ( pcm1808_sf0_o               ),
  .pcm1808_sf1_o        ( pcm1808_sf1_o               ),
  .ready_o              ( subsystems_ready            ),
  .switches_o           ( switches                    ),
  .cyc1000_button_stb_o (                             )
);

// Main thing
audio_engine audio_engine (
  .clk_i                ( sys_clk                       ),
  .srst_i               ( !subsystems_ready || sys_srst ),
  .mem_if               ( mem_if                        ),
  .i2s                  ( i2s                           ),
  .i2c_scl              ( i2c_scl_o                     ),
  .i2c_sda              ( i2c_sda_io                    ),
  .button_i             ( switches                      ),
  .cyc1000_led_o        (                               ),
  .user_led_o           ( user_led_o                    ),
  .sample_tick_o        ( sample_tick                   ),
  .spdif_o              ( spdif_o                       ),
  .cyc1000_button_i     (                               )
);

assign relay_o       =   subsystems_ready;
assign cyc1000_led_o = { subsystems_ready, 7'd0 };

endmodule

