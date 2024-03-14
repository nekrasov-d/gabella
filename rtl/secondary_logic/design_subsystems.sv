/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * This module contains all the routine needed to
*/

module design_sybsystems(
  i2s_if             i2s,
  sdram_if           sdram,
  external_memory_if mem_if [main_config::NUM_MEMORY_INTERFACES-1:0],
  input              clk_12m_i,
  input              cyc1000_button_i,
  input              sample_tick_i, // Synced to sys_clk_o
  input [3:1]        sw_i,
  output logic       sys_clk_o,
  output logic       sys_srst_o,
  output logic       pcm1808_fmt_o,
  output logic       pcm1808_sf0_o,
  output logic       pcm1808_sf1_o,
  output logic       ready_o,
  output logic [2:0] switches_o,
  output logic       cyc1000_button_stb_o
);

logic board_mem_ready;
logic i2s_devices_ready;
logic all_ready;
logic sys_clk_ready;
logic sdram_clk_ready;
logic i2s_mclk_ready;

//*********************************************************
sys_pll sys_pll (
  .inclk0  ( clk_12m_i       ),
  .c0      ( sys_clk_o       ),
  .locked  ( sys_clk_ready   )
);

logic [1:0] sys_clk_ready_d;
always_ff @( posedge sys_clk_o )
  sys_clk_ready_d <= {sys_clk_ready_d[0], sys_clk_ready};
assign sys_srst_o = ( sys_clk_ready_d == 2'b01 );

//*********************************************************
sdram_pll sdram_pll(
  .inclk0   ( clk_12m_i       ),
  .c0       ( sdram.clk       ),
  .locked   ( sdram_clk_ready )
);

logic [1:0] sdram_clk_ready_d;
always_ff @( posedge sdram.clk )
  sdram_clk_ready_d <= {sdram_clk_ready_d[0], sdram_clk_ready};
assign sdram.srst = ( sdram_clk_ready_d == 2'b01 );

//*********************************************************
i2s_pll i2s_pll(
  .inclk0   ( clk_12m_i       ),
  .c0       ( i2s.mclk        ),
  .locked   ( i2s_mclk_ready  )
);

logic [1:0] i2s_mclk_ready_d;
always_ff @( posedge i2s.mclk )
  i2s_mclk_ready_d <= {i2s_mclk_ready_d[0], i2s_mclk_ready };
assign i2s.srst = ( i2s_mclk_ready_d == 2'b01 );

//spdif_pll spdif_pll(
//  .inclk0   ( clk_12m_i       ),
//  .c0       ( spdif_clk_o     ),
//  .locked   (                 )
//);


//*****************************************************************************
// Check if everyone is ready
//*****************************************************************************

i2s_devices_ctrl i2s_ctrl(
  .i2s             ( i2s               ),
  .devices_ready_o ( i2s_devices_ready ),
  .pcm1808_fmt_o   ( pcm1808_fmt_o     ),
  .pcm1808_sf0_o   ( pcm1808_sf0_o     ),
  .pcm1808_sf1_o   ( pcm1808_sf1_o     )
);

always_ff @( posedge sys_clk_o )
  ready_o <= board_mem_ready && i2s_devices_ready;

//*****************************************************************************
// Debounce section
//*****************************************************************************

switch_debouncer #(
  .NUM            ( 3            ),
  .DEBOUNCE_DEPTH ( 22           )
) debouncer (
  .clk_i          ( sys_clk_o    ),
  .srst_i         ( sys_srst_o   ),
  .data_i         ( ~sw_i        ),
  .data_o         ( switches_o   )
);

// The button on cyc1000 has no bounces
logic [1:0] button_d;
always_ff @( posedge sys_clk_o )
  button_d <= { button_d[0], cyc1000_button_i };
assign cyc1000_button_stb_o = button_d[1] && !button_d[0];

//*****************************************************************************
// cyc1000 SDRAM
//*****************************************************************************

// SDRAM master interfaces are always 16-bit.
// Data could be either 16 bit or 24 bit
// If Data width is 16 bit, interfaces directly map one to another.
// If not, we need interface remap. The first wide one maps to 0 and 1 master,
// the second one maps to 2 and 3 and so.

external_memory_if #(
  .DATA_WIDTH ( 16 ),
  .ADDR_WIDTH ( main_config::MEM_ADDR_WIDTH )
) mem_16b_if [main_config::NUM_MEMORY_MASTERS-1:0] ();

genvar i;
generate
  if( main_config::DATA_WIDTH == 24 )
      for( i = 0; i < main_config::NUM_MEMORY_INTERFACES; i++ )
        begin : interface_remap
          assign mem_16b_if[i*2  ].write_address  = mem_if[i].write_address;
          assign mem_16b_if[i*2+1].write_address  = mem_if[i].write_address;
          assign mem_16b_if[i*2  ].read_address   = mem_if[i].read_address;
          assign mem_16b_if[i*2+1].read_address   = mem_if[i].read_address;
          assign mem_16b_if[i*2  ].writedata      = mem_if[i].writedata[15:0];
          assign mem_16b_if[i*2+1].writedata[7:0] = mem_if[i].writedata[23:16];
          assign mem_16b_if[i*2  ].write_enable   = mem_if[i].write_enable;
          assign mem_16b_if[i*2+1].write_enable   = mem_if[i].write_enable;
          assign mem_if[i].readdata[15:0]  = mem_16b_if[i*2  ].readdata;
          assign mem_if[i].readdata[23:16] = mem_16b_if[i*2+1].readdata[7:0];
        end // interface_remap
  else
    if( main_config::DATA_WIDTH == 16 )
      for( i = 0; i < main_config::NUM_MEMORY_MASTERS; i++ )
        begin : no_interface_remap
          assign mem_16b_if[i].write_address = mem_if[i].write_address;
          assign mem_16b_if[i].read_address  = mem_if[i].read_address;
          assign mem_16b_if[i].writedata     = mem_if[i].writedata;
          assign mem_16b_if[i].write_enable  = mem_if[i].write_enable;
          assign mem_if[i].readdata          = mem_16b_if[i].readdata;
        end // no_interface_remap
endgenerate

board_memory #(
  .NUM              ( main_config::NUM_MEMORY_MASTERS )
) board_memory (
  .sdram            ( sdram                           ),
  .sys_clk_i        ( sys_clk_o                       ),
  .sys_srst_i       ( sys_srst_o                      ),
  .action_strobe_i  ( ready_o && sample_tick_i        ),
  .mem_if           ( mem_16b_if                      ),
  .ready_o          ( board_mem_ready                 )
);

endmodule
