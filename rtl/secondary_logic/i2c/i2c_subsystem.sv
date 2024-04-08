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
