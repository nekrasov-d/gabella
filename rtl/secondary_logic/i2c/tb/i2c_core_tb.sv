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

module tb;

bit        clk;
bit        srst;

logic scl;
tri sda;

initial
  begin
    clk = 0;
    forever #5 clk = ~clk;
  end

initial
  begin
    srst     = 0;
    #5 srst  = 1;
    #15 srst = 0;
  end

//*****************************************************************************
//*****************************************************************************
avalon_mm_if #(.DATA_WIDTH(16),.ADDR_WIDTH(16)) amm_sgtl_if ();
avalon_mm_if #(.DATA_WIDTH(8),.ADDR_WIDTH(3)) amm_ads_if    ();

task automatic init_sgtl();
  amm_sgtl_if.writedata <= 0;
  amm_sgtl_if.address   <= 0;
  amm_sgtl_if.write     <= 0;
  amm_sgtl_if.read      <= 0;
endtask

task automatic init_ads();
  amm_ads_if.writedata  <= 0;
  amm_ads_if.address    <= 0;
  amm_ads_if.write      <= 0;
  amm_ads_if.read       <= 0;
endtask


task automatic sgtl_write( bit [15:0] data, address );
  @( posedge clk );
  amm_sgtl_if.writedata <= data;
  amm_sgtl_if.address   <= address;
  amm_sgtl_if.write     <= 1'b1;
  while( amm_sgtl_if.waitrequest )
    @( posedge clk );
  init_sgtl();
endtask

task automatic sgtl_read( input bit [15:0] address, output bit [15:0] data );
  @( posedge clk );
  amm_sgtl_if.address   <= address;
  amm_sgtl_if.read      <= 1'b1;
  fork
    while( amm_sgtl_if.waitrequest ) @( posedge clk );
    if( amm_sgtl_if.readdatavalid ) data = amm_sgtl_if.readdata;
  join
  init_sgtl();
endtask

task automatic ads_write( bit [2:0] address, bit[1:0] data );
  @( posedge clk );
  amm_ads_if.writedata <= data;
  amm_ads_if.address   <= address;
  amm_ads_if.write     <= 1'b1;
  while( amm_ads_if.waitrequest )
    @( posedge clk );
  init_ads();
endtask

task automatic ads_read( input bit [2:0] address, output bit [7:0] data );
  @( posedge clk );
  amm_ads_if.address   <= address;
  amm_ads_if.read      <= 1'b1;
  fork
    while( amm_ads_if.waitrequest ) @( posedge clk );
    if( amm_ads_if.readdatavalid ) data = amm_ads_if.readdata;
  join
  init_ads();
endtask


initial
  begin : main
    bit [15:0] sgtl_readdata;
    bit [7:0]  ads_readdata;

    @( posedge clk );
    init_sgtl();
    init_ads();
    repeat (10) @( posedge clk );
    sgtl_write( 16'haaaa, 16'h1111 );
    repeat (1000) @( posedge clk );
    sgtl_read( 16'habcd, sgtl_readdata );
    $write("\nsgtl_readdata: %0h\n", sgtl_readdata );
    repeat (1000) @( posedge clk );
    ads_write( 3'b000, 2'b11 );
    repeat (1000) @( posedge clk );
    ads_read( 3'b000, ads_readdata );
    $write("\nads_readdata: %0h\n", ads_readdata );
    repeat (1000) @( posedge clk );
    $stop;
  end

i2c_master dut(
  .clk_i                                  ( clk                         ),
  .srst_i                                 ( srst                        ),
  .amm_sgtl_if                            ( amm_sgtl_if                 ),
  .amm_ads_if                             ( amm_ads_if                  ),
  .scl_o                                  ( scl                         ),
  .sda_io                                 ( sda                         )
);


endmodule
