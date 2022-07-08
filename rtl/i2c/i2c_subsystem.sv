/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 * XXX: add annotation
*/

module i2c_subsystem #(
  parameter SYS_CLK_FREQ_HZ    = 50000000,
  parameter ADS_ROBOT_READ_EN  = 1,
  parameter ROBOT_READ_FREQ_HZ = 100,
  parameter SGTL_INIT_CONF_EN  = 1,
  parameter AMM_DATA_WIDTH     = 16,
  parameter AMM_ADDR_WIDTH     = 16
) (
  input                   clk_i,
  input                   srst_i,
  avalon_mm_if            csr_if,
  output logic            scl_o,
  inout                   sda_io,
  output logic [7:0][7:0] knob_level_o,
  output logic            sgtl_init_done_o
);

localparam SGTL = 0;
localparam ADS  = 1;

avalon_mm_if #(
  .DATA_WIDTH( AMM_DATA_WIDTH ),
  .ADDR_WIDTH( AMM_ADDR_WIDTH ))
csr_if_demuxed [1:0] ();

avalon_mm_if #(.DATA_WIDTH(16),.ADDR_WIDTH(16)) sgtl_if ();
avalon_mm_if #(.DATA_WIDTH(8),.ADDR_WIDTH(3))   ads_if  ();

amm_simple_demux #(
  .BASE_ADDR_0          ( 16'h0000             ),
  .BASE_ADDR_1          ( 16'h1000             ),
  .SLAVE_ADDR_BIT_MASK  ( 16'h0fff             )
) csr_if_demux (
  .master_if            ( csr_if               ),
  .slave_if             ( csr_if_demuxed       )
);

/*
sgtl_i2c_routine #(
  .INIT_CONF_EN         ( SGTL_INIT_CONF_EN    )
) sgtl_routine (
  .clk_i                ( clk_i                ),
  .srst_i               ( srst_i               ),
  .csr_if               ( csr_if_demuxed[SGTL] ),
  .sgtl_if              ( sgtl_if              ),
  .init_done_o          ( sgtl_init_done_o     )
);

*/
assign sgtl_init_done_o = 1'b1;
assign sgtl_if.write    = 1'b0;
assign sgtl_if.read     = 1'b0;

ads_i2c_routine #(
  .ROBOT_READ_EN        ( ADS_ROBOT_READ_EN    ),
  .SYS_CLK_FREQ_HZ      ( SYS_CLK_FREQ_HZ      ),
  .ROBOT_READ_FREQ_HZ   ( ROBOT_READ_FREQ_HZ   )
) ads_routine (
  .clk_i                ( clk_i                ),
  .srst_i               ( srst_i               ),
  .csr_if               ( csr_if_demuxed[ADS]  ),
  .ads_if               ( ads_if               ),
  .knob_level_o         ( knob_level_o         )
);

i2c_core #(
  .SYS_CLK_FREQ_HZ      ( SYS_CLK_FREQ_HZ      ),
  .I2C_FREQ_HZ          ( 100000               )
) i2c_core(
  .clk_i                ( clk_i                ),
  .srst_i               ( srst_i               ),
  .amm_sgtl_if          ( sgtl_if              ),
  .amm_ads_if           ( ads_if               ),
  .scl_o                ( scl_o                ),
  .sda_io               ( sda_io               )
);

endmodule
