/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 * XXX: add annotation
*/

module top_wrapper (
  input              clk_i,
  input              srst_i,
  avalon_mm_if       csr_if,
  external_memory_if mem_if [main_config::NUM_MEMORY_INTERFACES-1:0],
  ///
  input              i2s_lrclk,
  input              i2s_sclk,
  input              i2s_dout,
  output logic       i2s_din,
  output logic       i2c_scl,
  inout  wire        i2c_sda,
  output logic       relay_o,
  input        [3:1] button_i,
  output logic [7:0] cyc1000_led_o,
  output logic [3:0] user_led_o,
  output logic       sample_tick_o,
  input              cyc1000_button_i,
  output logic       fake_load_o
);

localparam DATA_WIDTH   = 24;

avalon_mm_if #(
  .DATA_WIDTH( 16 ),
  .ADDR_WIDTH( 16 ))
csr_if_demuxed [1:0] ();

logic [7:0] [7:0] knob_level;
logic [7:0] [7:0] knob_level_remap /* synthesis noprune */;
logic             init_done;
logic             din_dout_shortcut;

//assign din_dout_shortcut = 1'b0;

amm_simple_demux #(
  .BASE_ADDR_0             ( 16'h0000                    ),
  .BASE_ADDR_1             ( 16'h2000                    ),
  .SLAVE_ADDR_BIT_MASK     ( 16'h1fff                    )
) csr_if_demux (
  .master_if               ( csr_if                      ),
  .slave_if                ( csr_if_demuxed              )
);

i2c_subsystem #(
  .SYS_CLK_FREQ_HZ         ( 25_000_000                  ),
  .ADS_ROBOT_READ_EN       ( 1                           ),
  .ROBOT_READ_FREQ_HZ      ( 100                         ),
  .SGTL_INIT_CONF_EN       ( 0                           ),
  .AMM_DATA_WIDTH          ( 16                          ),
  .AMM_ADDR_WIDTH          ( 16                          )
) i2c_subsystem (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .csr_if                  ( csr_if_demuxed[0]           ),
  .scl_o                   ( i2c_scl                     ),
  .sda_io                  ( i2c_sda                     ),
  .knob_level_o            ( knob_level                  ),
  .sgtl_init_done_o        ( init_done                   )
);

logic [23:0] data_in;
logic [23:0] data_out;
logic [23:0] data_out_lim;
logic [23:0] data_from_app_core;
logic        sample_tick;

//*************************************************************
// It seems that DAC is kinda overdriven, so I had to attenuate output signal
// 8 times to stop hear some noise
logic [23:0] data_out_attenuated;
always_ff @( posedge clk_i )
  data_out_attenuated = { {4{data_out_lim[23]}}, data_out_lim[22:3] };

i2s_core #(
  .DATA_WIDTH              ( DATA_WIDTH                  ),
  .BUFFERS_AWIDTH          ( 8                           ),
  .LEFT_CHANNEL_EN         ( 1                           ),
  .RIGHT_CHANNEL_EN        ( 0                           ),
  .DIN_DOUT_SHORTCUT       ( 0                           )
) i2s_core (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( !init_done                  ),
  .din_dout_shortcut_i     ( din_dout_shortcut           ),
  .i2s_sclk_i              ( i2s_sclk                    ),
  .i2s_lrclk_i             ( i2s_lrclk                   ),
  .i2s_data_i              ( i2s_dout                    ),
  .i2s_data_o              ( i2s_din                     ),
  .left_data_i             ( data_out_attenuated         ),
  .left_data_val_i         ( sample_tick                 ),
  .left_data_o             ( data_in                     ),
  .left_data_val_o         ( sample_tick                 )
);

//*******************************************************************
//*******************************************************************
// Check max magnitude (for debugger)
logic [23:0] magnitude /* synthesis noprune */;
logic [23:0] magnitude_d1 /* synthesis noprune */;
logic [23:0] max /* synthesis noprune */;
assign magnitude = data_in[23] ? ~data_in[22:0] : data_in[22:0];

always_ff @( posedge clk_i )
  if( srst_i | cyc1000_button_i )
    max <= '0;
  else
    if( sample_tick )
      max <= magnitude > max ? magnitude : max;

assign
  knob_level_remap[0] = knob_level[7],
  knob_level_remap[1] = knob_level[5],
  knob_level_remap[2] = knob_level[6],
  knob_level_remap[3] = knob_level[4],
  knob_level_remap[4] = knob_level[0],
  knob_level_remap[5] = knob_level[3],
  knob_level_remap[6] = knob_level[1],
  knob_level_remap[7] = knob_level[2];


logic [3:0] main_leds;

logic led_special_mode_en;

generate
  if( main_config::SIN_GEN_ENABLE )
    begin : sin_gen
      sin_generator #(
        .DWIDTH        ( main_config::DATA_WIDTH ),
        .SIN_MIF       ( "scripts/sin.mif"       ),
        // 256 RES gives 44100 / 265 = ~172 Hz
        .RES           ( 256                     ) 
      ) sin_gen (
        .clk_i         ( clk_i                   ),
        .srst_i        ( srst_i                  ),
        .sample_tick_i ( sample_tick             ),
        .level_i       ( knob_level_remap[0]     ),
        // this value multiplies frequency if mult_en_i is '1'
        // must be a power of 2. Result frequency is (44100/RES)*mult_i
        .mult_i        ( 5'd16                   ),
        .mult_en_i     ( !button_i[2]            ),
        .data_o        ( data_from_app_core      )
      );
      assign led_special_mode_en = 1'b1;
    end // sin_gen
  else
    begin : regular
      application_core #(
        .DATA_WIDTH              ( main_config::DATA_WIDTH     ),
        .NOISE_FLOOR             ( 300                         )
      ) app_core (
        .clk_i                   ( clk_i                       ),
        .srst_i                  ( srst_i                      ),
        .sample_tick_i           ( sample_tick                 ),
        .csr_if                  ( csr_if_demuxed[1]           ),
        .mem_if                  ( mem_if                      ),
        .knob_level_i            ( knob_level_remap            ),
        .din_dout_shortcut_o     ( din_dout_shortcut           ),
        .button_i                ( button_i                    ),
        .main_leds_o             ( main_leds                   ),
        .dbg_leds_o              ( cyc1000_led_o               ),
        .data_i                  ( data_in                     ),
        .data_o                  ( data_from_app_core          )
      );
      assign led_special_mode_en = 1'b0;
    end // regular
endgenerate


led_controller #(
  .DWIDTH           ( main_config::DATA_WIDTH       ),
  .STARTUP_MUSIC_EN ( main_config::STARTUP_MUSIC_EN )
) led_controller (
  .clk_i            ( clk_i                         ),
  .srst_i           ( srst_i                        ),
  .sample_tick_i    ( sample_tick                   ),
  .mode_i           ( led_special_mode_en           ),
  .leds_i           ( main_leds                     ),
  .leds_o           ( user_led_o                    ),
  .data_i           ( data_from_app_core            ),
  .data_o           ( data_out                      )
);

limiter #(
  .DWIDTH          ( main_config::DATA_WIDTH  ),
  .THRESHOLD       ( main_config::LIMITER      )
) output_limter (
  .en_i            ( !button_i[2]  ),
  .data_i          ( data_out      ),
  .data_o          ( data_out_lim  ),
);

assign sample_tick_o = sample_tick;

endmodule
