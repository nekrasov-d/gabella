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
 * A pedalboard. Gathers effects into one chain.
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

import main_config::*;

module pedalboard #(
  parameter                     DATA_WIDTH  = 16
) (
  input                         clk_i,
  input                         srst_i,
  input                         sample_tick_i,
  external_memory_if            mem_if [main_config::NUM_MEMORY_INTERFACES-1:0],
  input [2:0]                   button_i,
  input [7:0][7:0]              knob_level_i,
  output logic                  din_dout_shortcut_o,
  output logic [3:0]            main_leds_o,
  output logic [7:0]            dbg_leds_o,
  input        [DATA_WIDTH-1:0] data_i,
  output logic [DATA_WIDTH-1:0] data_o
);

//*****************************************************************************
//*********************************** AUX *************************************

logic side_toggle;
assign side_toggle = button_i[1];

logic right_button_effects;
logic left_button_effects;

logic [2:0] button_d;
always_ff @( posedge clk_i )
  button_d <= button_i[2];

always_ff @( posedge clk_i )
  if( srst_i )
    right_button_effects <= '0;
  else
    if( button_i[2] && !button_d[2] )
      right_button_effects  <= !right_button_effects;

always_ff @( posedge clk_i )
  if( srst_i )
    left_button_effects <= '0;
  else
    if( button_i[0] && !button_d[0] )
      left_button_effects  <= !left_button_effects;

logic [3:0] main_leds;
assign main_leds[0] = left_button_effects;
assign main_leds[1] = left_button_effects;
assign main_leds[2] = right_button_effects;
assign main_leds[3] = right_button_effects;

led_controller led_ctrl (
  .clk_i            ( clk_i         ),
  .srst_i           ( srst_i        ),
  .sample_tick_i    ( sample_tick_i ),
  .mode_i           ( 1'b0          ), // 1'b1 is for constant blinking
  .leds_i           ( main_leds     ),
  .leds_o           ( main_leds_o   )
);

assign dbg_leds_o          = 8'd0;
assign din_dout_shortcut_o = 1'b0;


//localparam TD_MIN_TIME = 400; // in samples
//localparam TD_MAX_TIME = 100_000; // in samples
//localparam TD_TIME_WIDTH = $clog2(TD_MAX_TIME);
//logic [TD_TIME_WIDTH-1:0] td_time;
//logic                     td_time_valid_stb;
//
//logic side_toggle_d;
//logic st_posedge;
//logic st_either_edge;
//
//always_ff @( posedge clk_i )
//  side_toggle_d <= side_toggle;
//
//assign st_posedge     = side_toggle & !side_toggle_d;
//assign st_either_edge = side_toggle ^ side_toggle_d;
//
//
//time_detector #(
//  .TD_MAX_TIME        ( TD_MAX_TIME                 ),
//  .TD_MIN_TIME        ( TD_MIN_TIME                 ),
//  .DW                 ( DW                          ),
//) (
//  .clk_i              ( clk_i                       ),
//  .sample_tick_i      ( sample_tick_i               ),
//  .trigger_i          ( st_either_edge              ),
//  .detected_time_o    ( td_time                     ),
//  .valid_stb_o        ( td_time_valid_stb           ),
//);


//*****************************************************************************
//******************************* PEDALBOARD **********************************

logic [DATA_WIDTH-1:0] data_from_dut;
logic [DATA_WIDTH-1:0] data_from_wmd;
logic [DATA_WIDTH-1:0] data_from_wfds1;
logic [DATA_WIDTH-1:0] data_from_wfds2;
logic [DATA_WIDTH-1:0] data_from_noisegate;
logic [DATA_WIDTH-1:0] data_from_chorus;
logic [DATA_WIDTH-1:0] data_from_delay;
logic [DATA_WIDTH-1:0] data_from_tremolo;

// A plase to instantiate a design that currently is under test. A new filter for example
generate
  if( DUT_EN )
    begin : gen_dut
      design_under_test #(
        .DWIDTH               ( DATA_WIDTH                  )
      ) dut (
        .clk_i                ( clk_i                       ),
        .srst_i               ( srst_i                      ),
        .sample_tick_i        ( sample_tick_i               ),
        .buttons_i            (                             ),
        .data_i               ( data_i                      ),
        .data_o               ( data_from_dut               )
        );
    end // gen_dut
  else
    begin : bypass_dut
      assign data_from_dut = data_i;
    end // bypass_dut
endgenerate


generate
  if( WEIRD_MICRO_DELAY_EN )
    begin : gen_wmd
      localparam DELAY_AWIDTH = 11; // <-------------------- That makes it WEIRD!
      logic [DELAY_AWIDTH-1:0] delay_time;
      always_ff @( posedge clk_i )
          delay_time <= knob_level_i[DEL_TIME] << (DELAY_AWIDTH-8);

      delay #(
        .DWIDTH                    ( DATA_WIDTH                  ),
        .USE_EXTERNAL_MEMORY       ( 0                           ),
        .AWIDTH                    ( DELAY_AWIDTH                ),
        .FILTER_EN                 ( 1                           ),
        .FILTER_DEPTH              ( 16                          ),
        .FILTER_LEVEL_COMPENSATION ( 16                          ),
        .NO_FEEDBACK               ( 0                           ),
        .UNMUTE_EN                 ( 1                           )
      ) wmd (
        .clk_i                     ( clk_i                       ),
        .srst_i                    ( srst_i                      ),
        .sample_tick_i             ( sample_tick_i               ),
        .external_memory_if        ( mem_if[DELAY_IF]            ),
        .enable_i                  ( right_button_effects        ),
        .level_i                   ( knob_level_i[DEL_LEVEL]     ),
        .time_i                    ( delay_time                  ),
        .filter_en_i               ( 1'b0                        ),
        .data_i                    ( data_from_dut               ),
        .data_o                    ( data_from_wmd               )
      );
    end // gen_wmd
  else
    begin : bypass_wmd
      assign data_from_wmd = data_from_dut;
    end // bypass_wmd
endgenerate



generate
  if( WEIRD_FD_SOUNS1_EN )
    begin : gen_wfds1
      frequency_machine #(
        .INPUT_DW              ( DATA_WIDTH                  ),
        .DOWNSAMPLER_INIT_FILE ( main_config::FM_DOWNSAMPLER_INIT_FILE ),
        .RECOVERY              ( "ssidft"                    ),
        .WEIRD_MODE_EN         ( 1                           )
      ) fm (
        .clk_i                 ( clk_i                       ),
        .srst_i                ( srst_i                      ),
        .sample_tick_i         ( sample_tick_i               ),
        .cutoff_i              ( knob_level_i[WFDS2]         ),
        .mix_i                 ( knob_level_i[WFDS1]         ),
        .enable_i              ( right_button_effects        ),
        .bypass_dft_i          (                             ),
        .side_toggle_i         ( side_toggle                 ),
        .data_i                ( data_from_wmd               ),
        .data_o                ( data_from_wfds1             ),
        .sat_alarm_1_o         (                             ),
        .sat_alarm_2_o         (                             )
      );
    end // gen_wfds1
  else
    begin : bypass_wfds1
      assign data_from_wfds1 = data_from_wmd;
    end // bypass_wfds1
endgenerate


generate
  if( WEIRD_FD_SOUNS2_EN )
    begin : gen_wfds2
      frequency_machine #(
        .INPUT_DW              ( DATA_WIDTH                  ),
        .DOWNSAMPLER_INIT_FILE ( main_config::FM_DOWNSAMPLER_INIT_FILE ),
        .RECOVERY              ( "oscillator"                ),
        .WEIRD_MODE_EN         ( 1                           )
      ) fm (
        .clk_i                 ( clk_i                       ),
        .srst_i                ( srst_i                      ),
        .sample_tick_i         ( sample_tick_i               ),
        .cutoff_i              ( 8'd0                        ),
        .mix_i                 ( knob_level_i[WFDS2]         ),
        .enable_i              ( right_button_effects        ),
        .bypass_dft_i          (                             ),
        .side_toggle_i         ( side_toggle                 ),
        .data_i                ( data_from_wfds1             ),
        .data_o                ( data_from_wfds2             ),
        .sat_alarm_1_o         (                             ),
        .sat_alarm_2_o         (                             )
      );
    end // gen_wfds2
  else
    begin : bypass_wfds2
      assign data_from_wfds2 = data_from_wfds1;
    end // bypass_wfds2
endgenerate



generate
  if( NOISEGATE_EN )
    begin : gen_noisegate
      assign data_from_noisegate = data_from_dut;
      /*
      noisegate #(
        .THRESHOLD      ( main_config::NOISEGATE_THRESHOLD )
      ) noisegate (
        .clk_i          ( clk_i                            ),
        .srst_i         ( srst_i                           ),
        .sample_tick_i  ( sample_tick_i                    ),
        .enable_i       ( 1'b1                             ),
        .data_i         ( data_from_wfds2                  ),
        .data_o         ( data_from_noisegate              )
      );
      */
    end // gen_noisegate
  else
    begin : bypass_noisegate
      assign data_from_noisegate = data_from_wfds2;
    end // bypass_noisegate
endgenerate


generate
  if( CHORUS_EN )
    begin : gen_chorus
      chorus #(
        .DWIDTH           ( DATA_WIDTH                   ),
        .MIN_TIME         ( main_config::CHORUS_MIN_TIME ),
        .MAX_TIME         ( main_config::CHORUS_MAX_TIME )
      ) chorus (
        .clk_i            ( clk_i                        ),
        .srst_i           ( srst_i                       ),
        .sample_tick_i    ( sample_tick_i                ),
        .enable_i         ( left_button_effects         ),
        .level_i          ( knob_level_i[CHORUS]         ),
        .depth_i          ( main_config::CHORUS_DEPTH    ),
        .data_i           ( data_from_noisegate          ),
        .data_o           ( data_from_chorus             )
      );
    end // gen_chorus
  else
    begin : bypass_chorus
      assign data_from_chorus = data_from_noisegate;
    end // bypass_chorus
endgenerate


generate
  if( DELAY_EN )
    begin : gen_delay
      // XXX: SDRAM seems broken!
      localparam USE_EXTERNAL_MEMORY = 0;
      localparam DELAY_AWIDTH = 15; // If USE_EXTERNAL_MEMORY==0 it can require
                                    //  more M9Ks than the chip has
      logic [DELAY_AWIDTH-1:0] delay_time;
      // It allows to change delay time to only onve in about 160 ms.
      // Reduces noise when you turn time knob.
      logic [21:0] counter;
      always_ff @( posedge clk_i )
        counter <= counter + 1'b1;

      always_ff @( posedge clk_i )
        if( counter == '0 )
          delay_time <= knob_level_i[DEL_TIME] << (DELAY_AWIDTH-8);

      delay #(
        .DWIDTH                    ( DATA_WIDTH                  ),
        .USE_EXTERNAL_MEMORY       ( USE_EXTERNAL_MEMORY         ),
        .AWIDTH                    ( DELAY_AWIDTH                ),
        .FILTER_EN                 ( 1                           ),
        .FILTER_DEPTH              ( 16                          ),
        .FILTER_LEVEL_COMPENSATION ( 16                          ),
        .NO_FEEDBACK               ( 0                           ),
        .UNMUTE_EN                 ( 1                           )
      ) delay (
        .clk_i                     ( clk_i                       ),
        .srst_i                    ( srst_i                      ),
        .sample_tick_i             ( sample_tick_i               ),
        .external_memory_if        ( mem_if[DELAY_IF]            ),
        .enable_i                  ( right_button_effects        ),
        .level_i                   ( knob_level_i[DEL_LEVEL]     ),
        .time_i                    ( delay_time                  ),
        .filter_en_i               ( !side_toggle                ),
        .data_i                    ( data_from_chorus            ),
        .data_o                    ( data_from_delay             )
      );
    end // gen_delay
  else
    begin : bypass_delay
      assign data_from_delay = data_from_chorus;
    end // bypass_delay
endgenerate



generate
  if( TREMOLO_EN )
    begin : gen_tremolo
//      tremolo #(
//        .DW                   ( DATA_WIDTH                            ),
//        .FREQ_TABLE_FILE      ( "rtl/tremolo/tremolo_frequency_table.mem" ),
//        .FREQ_DIVISOR_FACTOR  ( 2                                     )
//      ) trem (
//        .clk_i                ( clk_i                       ),
//        .srst_i               ( srst_i                      ),
//        .sample_tick_i        ( sample_tick_i               ),
//        .frequency_number_i   ( knob_level_i[TREM_SPEED]    ),
//        .level_i              ( knob_level_i[TREM_DEPTH]    ),
//        .enable_i             ( left_button_effects         ),
//        .data_i               ( data_from_delay            ),
//        .data_o               ( data_from_tremolo           )
//      );

    end // gen_tremolo
  else
    begin : bypass_tremolo
      assign data_from_tremolo = data_from_delay;
    end // bypass_tremolo
endgenerate

assign data_o = data_from_tremolo;

endmodule
