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
 * All the stuff related to audio. It contains the main thin this design is for,
 * pedalboard. As well as communicaion with audio devices on the PCB (ADC/DAC)
 *
 * The second level of the design hierarchy
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

module audio_engine (
  input              clk_i,
  input              srst_i,
  external_memory_if mem_if [main_config::NUM_MEMORY_INTERFACES-1:0],
  i2s_if             i2s,
  output logic       i2c_scl,
  inout  wire        i2c_sda,
  input        [3:1] button_i,
  output logic [7:0] cyc1000_led_o,
  output logic [3:0] user_led_o,
  output logic       sample_tick_o,
  output logic       spdif_o,
  input              cyc1000_button_i
);

localparam DATA_WIDTH = main_config::DATA_WIDTH;

logic [7:0] [7:0]      knob_level;
logic [7:0] [7:0]      knob_level_remap;
logic                  din_dout_shortcut;
logic [DATA_WIDTH-1:0] data_in;
logic [DATA_WIDTH-1:0] data_out;
logic                  sample_tick;
logic [3:0]            main_leds;


i2c_subsystem #(
  .SYS_CLK_FREQ_HZ         ( 25_000_000                  ),
  .ADS_ROBOT_READ_EN       ( 1                           ),
  .ROBOT_READ_FREQ_HZ      ( 100                         )
) i2c_subsystem (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .scl_o                   ( i2c_scl                     ),
  .sda_io                  ( i2c_sda                     ),
  .knob_level_o            ( knob_level                  )
);

assign
  knob_level_remap[0] = knob_level[7],
  knob_level_remap[1] = knob_level[5],
  knob_level_remap[2] = knob_level[6],
  knob_level_remap[3] = knob_level[4],
  knob_level_remap[4] = knob_level[0],
  knob_level_remap[5] = knob_level[3],
  knob_level_remap[6] = knob_level[1],
  knob_level_remap[7] = knob_level[2];


i2s_receiver #(
  .DATA_WIDTH              ( DATA_WIDTH                  )
) i2s_receiver (
  .i2s                     ( i2s                         ),
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .data_o                  ( data_in                     ),
  .data_val_o              ( sample_tick                 )
);


i2s_transmitter #(
  .DATA_WIDTH              ( DATA_WIDTH                  )
) i2s_transmitter (
  .i2s                     ( i2s                         ),
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .din_dout_shortcut_i     ( din_dout_shortcut           ),
  .data_i                  ( data_out                    ),
  .data_val_i              ( sample_tick                 )
);


spdif_transmitter #(
  .DATA_WIDTH              ( DATA_WIDTH                  )
) spdif_transmitter (
  .sys_clk_i               ( clk_i                       ),
  .sys_srst_i              ( srst_i                      ),
  .spdif_clk_i             ( i2s.mclk                    ),
  .data_i                  ( data_out                    ),
  .valid_i                 ( sample_tick                 ),
  .spdif_o                 ( spdif_o                     )
);


pedalboard #(
  .DATA_WIDTH              ( DATA_WIDTH                  )
) app_core (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .sample_tick_i           ( sample_tick                 ),
  .mem_if                  ( mem_if                      ),
  .knob_level_i            ( knob_level_remap            ),
  .din_dout_shortcut_o     ( din_dout_shortcut           ),
  .button_i                ( button_i                    ),
  .main_leds_o             ( user_led_o                  ),
  .dbg_leds_o              ( cyc1000_led_o               ),
  .data_i                  ( data_in                     ),
  .data_o                  ( data_out                    )
);

assign sample_tick_o = sample_tick;

endmodule
