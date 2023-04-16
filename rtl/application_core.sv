/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * A pedalboard. Gathers effects into one chain.
*/

import main_config::*;

module application_core #(
  parameter                     DATA_WIDTH  = 16,
  parameter                     NOISE_FLOOR = 300
) (
  input                         clk_i,
  input                         srst_i,
  input                         sample_tick_i,
  avalon_mm_if                  csr_if,

  external_memory_if            mem_if [main_config::NUM_MEMORY_INTERFACES-1:0],

  input [2:0]                   button_i,

  input [7:0][7:0]              knob_level_i,
  output logic                  din_dout_shortcut_o,

  output logic [3:0]            main_leds_o,
  output logic [7:0]            dbg_leds_o,

  input        [DATA_WIDTH-1:0] data_i,
  output logic [DATA_WIDTH-1:0] data_o
);


//************************************************************************
//************************************************************************

logic [31:0] ctrl_reg;

assign csr_if.waitrequest    = '0;

always_ff @( posedge clk_i )
  csr_if.readdatavalid <= csr_if.read;

always_ff @( posedge clk_i )
  if( csr_if.write )
    ctrl_reg <= csr_if.writedata;

//************************************************************************
//*************************** FACILITIES *********************************

/*
logic debug_recorder_en;
logic debug_recorder_en_d1;
logic debug_recorder_start;

assign debug_recorder_en = ctrl_reg[3];

assign din_dout_shortcut_o = 1'b0;//ctrl_reg[4];

always_ff @( posedge clk_i )
  debug_recorder_en_d1 <= debug_recorder_en;

assign debug_recorder_start = debug_recorder_en && !debug_recorder_en_d1;

logic [DATA_WIDTH-1:0] debug_recorder_data;
logic                  debug_recorder_data_val;

generate
  if( DEBUG_RECORDER_EN )
    begin : gen_recorder
      debug_recorder #(
        .SAMPLE_TICK_RATE    ( 44100                    ),
        .LENGTH_SEC          ( 2                        )
      ) recorder_inst (
        .clk_i               ( clk_i                    ),
        .srst_i              ( srst_i                   ),
        .sample_tick_i       ( sample_tick_i            ),
        .data_i              ( data_i                   ),
        .start_i             ( debug_recorder_start     ),
        .output_data_o       ( debug_recorder_data      ),
        .data_valid_o        ( debug_recorder_data_val  ),
        .output_data_pull_i  ( csr_if.read              )
      );
    end // gen_recorder
endgenerate

//assign csr_if.readdata[31]   = debug_recorder_data_val;
assign csr_if.readdata[DATA_WIDTH-1:0] = debug_recorder_data;
*/


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


assign main_leds_o[0] = left_button_effects;
assign main_leds_o[1] = left_button_effects;

assign main_leds_o[2] = right_button_effects;
assign main_leds_o[3] = right_button_effects;

//*****************************************************************************
//******************************* PEDALBOARD **********************************

logic [DATA_WIDTH-1:0] data_from_swell;
logic [DATA_WIDTH-1:0] data_from_drive;
logic [DATA_WIDTH-1:0] data_from_chorus;
logic [DATA_WIDTH-1:0] data_from_delay;
logic [DATA_WIDTH-1:0] data_from_reverb;

generate
  if( SWELL_EN )
    begin : gen_swell

      logic swell_en;

      assign swell_en = ( knob_level_i[SWELL] == 0 );

      swell #(
        .DWIDTH         ( DATA_WIDTH                  )
      ) swell (
        .clk_i          ( clk_i                       ),
        .srst_i         ( srst_i                      ),
        .sample_tick_i  ( sample_tick_i || !swell_en  ),
        .enable_i       ( right_button_effects        ),
        .noise_floor_i  ( 16'h40                      ),
        .threshold_i    ( knob_level_i[SWELL] << 3    ),
        .data_i         ( data_i                      ),
        .data_o         ( data_from_swell             )
      );
    end // gen_swell
  else
    begin : no_swell
      assign data_from_swell = data_i;
    end // no_swell
endgenerate


generate
  if( 0 )// DRIVE_EN )
    begin : gen_drive
      /*
      drive #(
        .TRANSFER_MIF   ( "../scripts/transfer.mif"  )
      ) drive (
        .clk_i          ( clk_i                       ),
        .srst_i         ( srst_i                      ),
        .sample_tick_i  ( sample_tick_i               ),
        .enable_i       ( left_button_effects         ),
        .pre_gain_i     ( 1'b1                        ),
        .mix_i          ( knob_level_i[DRIVE]         ),
        .filter_en_i    ( !button_i[1]                ),
        .data_i         ( data_from_swell             ),
        .data_o         ( data_from_drive             )
      );
      */
    end // gen_drive
  else
    begin : no_drive
      assign data_from_drive = data_from_swell;
    end // no_fuzz
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
        .data_i           ( data_from_drive             ),
        .data_o           ( data_from_chorus            )
      );
    end // gen_chorus
  else
    begin : no_chorus
      assign data_from_chorus = data_from_drive;
    end
endgenerate


generate
  if( DELAY_EN )
    begin : gen_delay
      localparam DELAY_AWIDTH = 15;

      logic [DELAY_AWIDTH-1:0] delay_time;

      // Разрешает смену времени дилея только раз в ~160 миллисекунд
      // это уменьшит количество шума при перестройке
      logic [21:0] counter;
      always_ff @( posedge clk_i )
        counter <= counter + 1'b1;

      always_ff @( posedge clk_i )
        if( counter == '0 )
          delay_time <= knob_level_i[DEL_TIME] << (DELAY_AWIDTH-8);

      logic delay_en;

      assign delay_en = (knob_level_i[DEL_LEVEL] > 0 ) && ( knob_level_i[DEL_TIME] > 0 );

      delay #(
        .DWIDTH             ( DATA_WIDTH                  ),
        .USE_EXTERNAL_MEMORY ( 1                          ),
        .AWIDTH             ( DELAY_AWIDTH                ),
        .FILTER_EN          ( 1                           ),
        .FILTER_DEPTH       ( 16                          ),
        .FILTER_LEVEL_COMPENSATION ( 16                   ),
        .NO_FEEDBACK        ( 0                           ),
        .UNMUTE_EN          ( 1                           )
      ) delay (
        .clk_i              ( clk_i                       ),
        .srst_i             ( srst_i                      ),
        .sample_tick_i      ( sample_tick_i               ),
        .external_memory_if ( mem_if[DELAY_IF]            ),
        .enable_i           ( right_button_effects        ),
        .level_i            ( knob_level_i[DEL_LEVEL]     ),
        .time_i             ( delay_time                  ),
        .filter_en_i        ( !button_i[1]                ),
        .data_i             ( data_from_chorus            ),
        .data_o             ( data_from_delay             )
      );
    end // gen_delay
  else
    begin : no_delay
      assign data_from_delay = data_from_chorus;
    end
endgenerate

generate
  if( REVERB_EN )
    begin : gen_reverb

      reverb #(
        .DWIDTH                  ( DATA_WIDTH            ),
        .NUM                     ( reverb_pkg::NUM       ),
        .DELAYS                  ( reverb_pkg::DELAYS    ),
        .FILTER_EN               ( 0                     ),
        .FILTER_DEPTH            ( 8                     ),
        .CHORUS_EN               ( 0                     ),
        .PRE_DELAY_EN            ( 1                     )
      ) reverb (
        .clk_i                   ( clk_i                 ),
        .srst_i                  ( srst_i                ),
        .sample_tick_i           ( sample_tick_i         ),
        .enable_i                ( right_button_effects  ),
        .main_memory_if          ( mem_if[1]             ),
        .post_delay_0_memory_if  ( mem_if[2]             ),
        .post_delay_1_memory_if  ( mem_if[3]             ),
        .post_delay_2_memory_if  ( mem_if[4]             ),
        .post_delay_3_memory_if  ( mem_if[5]             ),
        .post_delay_enable_i     ( 4'hf                  ),
        .post_delay_level_i      ( knob_level_i[REV_DECAY] ),

        .level_i                 ( 8'd255                ),
        .pre_delay_i             ( 16'd1000              ),
        .mix_i                   ( knob_level_i[REV_MIX] ),
        .data_i                  ( data_from_delay       ),
        .data_o                  ( data_from_reverb      )
      );
    end // gen_reverb
  else
    begin : no_reverb
      assign data_from_reverb = data_from_delay;
    end
endgenerate

assign data_o = data_from_reverb;

endmodule
