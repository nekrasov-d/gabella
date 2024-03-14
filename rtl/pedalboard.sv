/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * --------------------------------------------------------------------------
 *
 * A pedalboard. Gathers effects into one chain.
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

//*****************************************************************************
//******************************* PEDALBOARD **********************************

logic [DATA_WIDTH-1:0] data_from_dut;
logic [DATA_WIDTH-1:0] data_from_noisegate;
logic [DATA_WIDTH-1:0] data_from_chorus;
logic [DATA_WIDTH-1:0] data_from_delay;
logic [DATA_WIDTH-1:0] data_from_tremolo;


// A plase to instantiate a design that currently is under test. A new filter for example
generate
  if( DUT_EN )
    begin : gen_dut
      design_under_test #(
        .DWIDTH         ( DATA_WIDTH                  )
      ) dut (
        .clk_i          ( clk_i                       ),
        .srst_i         ( srst_i                      ),
        .sample_tick_i  ( sample_tick_i               ),
        .buttons_i      (                             ),
        .data_i         ( data_i                      ),
        .data_o         ( data_from_dut               )
      );
    end // gen_dut
  else
    begin : bypass_dut
      assign data_from_dut = data_i;
    end // bypass_dut
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
        .data_i         ( data_from_dut                    ),
        .data_o         ( data_from_noisegate              )
      );
      */
    end // gen_noisegate
  else
    begin : bypass_noisegate
      assign data_from_noisegate = data_from_dut;
    end // bypass_noisegate
endgenerate


generate
  if( CHORUS_EN )
    begin : gen_chorus
      chorus #(
        .DWIDTH           ( DATA_WIDTH                  ),
        .MIN_TIME         ( 'h370                       ),
        .MAX_TIME         ( 'h530                       )
      ) chorus (
        .clk_i            ( clk_i                       ),
        .srst_i           ( srst_i                      ),
        .sample_tick_i    ( sample_tick_i               ),
        .enable_i         ( right_button_effects        ),
        .level_i          ( knob_level_i[CHORUS]        ),
        .depth_i          ( 8'h80                       ),
        .data_i           ( data_from_noisegate         ),
        .data_o           ( data_from_chorus            )
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
      //localparam DELAY_AWIDTH = 12;
      localparam DELAY_AWIDTH = 15;
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
        .USE_EXTERNAL_MEMORY       ( 1                           ),
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
      tremolo #(
        .DW                   ( DATA_WIDTH                            ),
        .FREQ_TABLE_FILE      ( "rtl/tremolo/tremolo_frequency_table.mif" ),
        .FREQ_DIVISOR_FACTOR  ( 2                                     )
      ) trem (
        .clk_i                ( clk_i                       ),
        .srst_i               ( srst_i                      ),
        .sample_tick_i        ( sample_tick_i               ),
        .frequency_number_i   ( knob_level_i[TREM_SPEED]    ),
        .level_i              ( knob_level_i[TREM_DEPTH]    ),
        .enable_i             ( left_button_effects         ),
        .data_i               ( data_from_delay            ),
        .data_o               ( data_from_tremolo           )
      );

    end // gen_tremolo
  else
    begin : bypass_tremolo
      assign data_from_tremolo = data_from_delay;
    end // bypass_tremolo
endgenerate

assign data_o = data_from_tremolo;

endmodule
