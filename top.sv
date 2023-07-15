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

module top(
  input              clk_12m_i,

  output logic       i2s_mclk_o,
  output logic       i2s_bclk_o,
  output logic       i2s_lrclk_o,
  output logic       i2s_din_o,
  input              i2s_dout_i,

  output logic       pcm1808_fmt_o,
  output logic       pcm1808_sf0_o,
  output logic       pcm1808_sf1_o,

  output logic       i2c_scl_o,
  inout  wire        i2c_sda_io,

  input              cyc1000_button_i,

  input        [3:1] sw_i,
  output logic [7:0] cyc1000_led_o,
  output logic [4:1] user_led_o,
  output logic       relay_o,

  output logic       D11_R,
  output logic       D12_R,

//  output logic       fake_load_o,
  output logic       dac_mute_o,

  // SDRAM pins
  output logic [13:0] a_o,
  output logic [1:0]  bs_o,
  inout wire   [15:0] dq_io,
  output logic [1:0]  dqm_o,
  output logic        cs_o,
  output logic        ras_o,
  output logic        cas_o,
  output logic        we_o,
  output logic        cke_o,
  output logic        sdram_clk_o
);

// Constant drive
assign D11_R = 1'bz;
assign D12_R = 1'bz;
assign dac_mute_o = 1'b0;
assign a_o[13:12] = 2'b00;

logic sample_tick /* synthesis noprune */;
logic board_mem_ready;
logic i2s_devices_ready;
logic ready;

//*****************************************************************************
// Clocks and resets
//*****************************************************************************

// I know this is weird, just having fun
// receives <clk name> (as CLK)
// generates <clk name>_srst
// use <clk name>_ready as an async trigger event (active high)
`define GEN_SRST(CLK, SRST)                     \
  logic       CLK;                              \
  logic       SRST;                             \
  logic       ``CLK``_ready;                    \
  logic [1:0] ``CLK``_ready_d;                  \
  always_ff @( posedge ``CLK )                  \
    begin                                       \
      ``CLK``_ready_d[0] <= ``CLK``_ready;      \
      ``CLK``_ready_d[1] <= ``CLK``_ready_d[0]; \
    end                                         \
  assign ``SRST = ``CLK``_ready_d[0] && !``CLK``_ready_d[1];

`GEN_SRST(i2s_mclk, i2s_mclk_srst) // i2s_mclk_ready -> i2s_mclk_srst
`GEN_SRST(sys_clk,  sys_srst)      // sys_clk_ready  -> sys_clk_srst
`GEN_SRST(sdram_clk, sdram_srst)     // sdram_clk_ready -> sdram_clk_srst

sys_pll sys_pll (
  .inclk0  ( clk_12m_i      ),
  .c0      ( sys_clk        ),
  .c1      ( i2s_mclk       ),
  .locked  ( i2s_mclk_ready ) // declared by macro `GEN_SRST
);

assign sys_clk_ready = i2s_mclk_ready; //declared by macro `GEN_SRST


sdram_pll sdram_pll(
  .inclk0   ( clk_12m_i       ),
  .c0       ( sdram_clk       ),
  .locked   ( sdram_clk_ready ) //declared by macro `GEN_SRST
);

i2s_devices_ctrl i2s_ctrl(
  .clk_i           ( i2s_mclk          ),
  .srst_i          ( i2s_mclk_srst     ),
  .bclk_o          ( i2s_bclk_o        ),
  .lrclk_o         ( i2s_lrclk_o       ),
  .devices_ready_o ( i2s_devices_ready ),
  .pcm1808_fmt_o   ( pcm1808_fmt_o     ),
  .pcm1808_sf0_o   ( pcm1808_sf0_o     ),
  .pcm1808_sf1_o   ( pcm1808_sf1_o     )
);

assign i2s_mclk_o = i2s_mclk;
//*****************************************************************************
// Debounce section
//*****************************************************************************
logic [2:0] sw_debounced;

switch_debouncer #(
  .NUM            ( 3            ),
  .DEBOUNCE_DEPTH ( 22           )
) debouncer (
  .clk_i          ( sys_clk      ),
  .srst_i         ( sys_srst     ),
  .data_i         ( ~sw_i        ),
  .data_o         ( sw_debounced )
);

// The button on cyc1000 has no bounces
logic [1:0] button_d;
logic       button_pressed_stb;

always_ff @( posedge sys_clk )
  begin
    button_d[0] <= cyc1000_button_i;
    button_d[1] <= button_d[0];
  end

assign button_pressed_stb = button_d[1] && !button_d[0];

//*****************************************************************************
// Application core
//*****************************************************************************

// For a case if we will use jtag2avalon
avalon_mm_if #( .DATA_WIDTH( 16 ), .ADDR_WIDTH( 16 )) csr_if ();

external_memory_if #(
  .DATA_WIDTH ( main_config::DATA_WIDTH     ),
  .ADDR_WIDTH ( main_config::MEM_ADDR_WIDTH )
) mem_if [main_config::NUM_MEMORY_INTERFACES-1:0] ();

always_ff @( posedge sys_clk )
  ready <= board_mem_ready && i2s_devices_ready;

top_wrapper top_wrapper (
  .clk_i                ( sys_clk            ),
  .srst_i               ( !ready || sys_srst ),
  .csr_if               ( csr_if             ),
  .mem_if               ( mem_if            ),
  .i2s_lrclk            ( i2s_lrclk_o       ),
  .i2s_sclk             ( i2s_bclk_o        ),
  .i2s_dout             ( i2s_dout_i        ),
  .i2s_din              ( i2s_din_o         ),
  .i2c_scl              ( i2c_scl_o         ),
  .i2c_sda              ( i2c_sda_io        ),
  .relay_o              ( ),//relay_o       ),
  .button_i             ( sw_debounced      ),
  .cyc1000_led_o        ( cyc1000_led_o[6:0] ),
  .user_led_o           ( user_led_o        ),
  .sample_tick_o        ( sample_tick       ),
  .cyc1000_button_i     ( button_pressed_stb ),
  .fake_load_o          (                   )
);

assign relay_o = ready;
assign cyc1000_led_o[7] = relay_o;

//*****************************************************************************
// Iterfaces
//*****************************************************************************

localparam JTAG_TO_AVALON_EN = 0;

generate
  if( JTAG_TO_AVALON_EN )
    begin : gen_jtag2avalon
      // jtag2avalon instance
    end
  else
    begin : no_jtag2valon
      assign csr_if.read  = 1'b0;
      assign csr_if.write = 1'b0;
    end
endgenerate

//*****************************************************************************
// cyc1000 SDRAM
//*****************************************************************************

external_memory_if #(
  .DATA_WIDTH ( 16 ),
  .ADDR_WIDTH ( main_config::MEM_ADDR_WIDTH )
) mem_16b_if [main_config::NUM_MEMORY_MASTERS-1:0] ();

// SDRAM master interfaces are always 16-bit.
// Data could be either 16 bit or 24 bit
// If Data width is 16 bit, interfaces directly map one to another.
// If not, we need interface remap. The first wide one maps to 0 and 1 master,
// the second one maps to 2 and 3 and so.
genvar i;
generate
  if( main_config::DATA_WIDTH != 16 )
    begin
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
    end
  else
    begin
      for( i = 0; i < main_config::NUM_MEMORY_MASTERS; i++ )
        begin : no_interface_remap
          assign mem_16b_if[i].write_address = mem_if[i].write_address;
          assign mem_16b_if[i].read_address  = mem_if[i].read_address;
          assign mem_16b_if[i].writedata     = mem_if[i].writedata;
          assign mem_16b_if[i].write_enable  = mem_if[i].write_enable;
          assign mem_if[i].readdata          = mem_16b_if[i].readdata;
        end // no_interface_remap
    end
endgenerate


board_memory #(
  .NUM                                    ( main_config::NUM_MEMORY_MASTERS )
) board_memory (
  .sdram_clk_i                            ( sdram_clk                    ),
  .sdram_srst_i                           ( sdram_srst                   ),
   // sys clk somain
  .sys_clk_i                              ( sys_clk                     ),
  .sys_srst_i                             ( sys_srst                    ),
  .action_strobe_i                        ( ready && sample_tick        ),
  .mem_if                                 ( mem_16b_if                  ),
  .ready_o                                ( board_mem_ready             ),
  // documentation names + direction suffix
  .a_o                                    ( a_o[11:0]                   ),
  .bs_o                                   ( bs_o                        ),
  .dq_io                                  ( dq_io                       ),
  .dqm_o                                  ( dqm_o                       ),
  .cs_o                                   ( cs_o                        ),
  .ras_o                                  ( ras_o                       ),
  .cas_o                                  ( cas_o                       ),
  .we_o                                   ( we_o                        ),
  .cke_o                                  ( cke_o                       )
);

assign sdram_clk_o = sdram_clk;

endmodule

