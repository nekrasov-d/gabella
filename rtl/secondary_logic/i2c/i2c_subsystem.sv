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

module i2c_subsystem #(
  parameter SYS_CLK_FREQ_HZ    = 50000000,
  parameter ADS_ROBOT_READ_EN  = 1,
  parameter ROBOT_READ_FREQ_HZ = 100 // Check knobs 100 times per second
) (
  input                   clk_i,
  input                   srst_i,
  output logic            scl_o,
  inout                   sda_io,
  output logic [7:0][7:0] knob_level_o
);

avalon_mm_if #(.DATA_WIDTH(16),.ADDR_WIDTH(16)) sgtl_if ();
avalon_mm_if #(.DATA_WIDTH(8),.ADDR_WIDTH(3))   ads_if  ();

// Once we had this device, but we don't use it anymore.
logic [17:0] nc;
assign { sgtl_if.writedata, sgtl_if.address, sgtl_if.write, sgtl_if.read } = '0;
//assign nc = { sgtl_if.readdata, sgtl_if.readdatavalid, sgtl_if.waitrequest };

ads_i2c_routine #(
  .ROBOT_READ_EN        ( ADS_ROBOT_READ_EN    ),
  .SYS_CLK_FREQ_HZ      ( SYS_CLK_FREQ_HZ      ),
  .ROBOT_READ_FREQ_HZ   ( ROBOT_READ_FREQ_HZ   )
) ads_routine (
  .clk_i                ( clk_i                ),
  .srst_i               ( srst_i               ),
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
