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

module tb;

bit        clk;
bit        srst;

logic scl;
tri sda;

bit [7:0][7:0] knob_level;

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
avalon_mm_if #(.DATA_WIDTH(32),.ADDR_WIDTH(32)) csr_if ();


task automatic write( bit [31:0] data, bit[31:0] address );
  @( posedge clk );
  csr_if.writedata <= data;
  csr_if.address   <= address;
  csr_if.write     <= 1'b1;
  @( posedge clk );
  while( csr_if.waitrequest )
    @( posedge clk );
  init_csr_if();
endtask


task automatic read( input bit [31:0] address, output bit[31:0] data );
  @( posedge clk );
  csr_if.address   <= address;
  csr_if.read      <= 1'b1;
  @( posedge clk );
  fork
    while( csr_if.waitrequest ) @( posedge clk );
    if( csr_if.readdatavalid ) data = csr_if.readdata;
  join
  init_csr_if();
endtask


task automatic init_csr_if();
  csr_if.writedata <= 0;
  csr_if.address   <= 0;
  csr_if.write     <= 0;
  csr_if.read      <= 0;
endtask

initial
  begin : main
    bit [31:0] readdata;
    init_csr_if();
    repeat(10) @( posedge clk );
    $write("\n\n**************************************************\n\n");
    fork
      i2c_monitor();
    join_none

    repeat(100) @(posedge clk );
//    write(32'h0000_00000, 16'h0022);
    repeat(100) @( posedge clk );
//    read(16'h000a, readdata);
    repeat(100) @( posedge clk );
    //$stop;
    repeat (220000) @( posedge clk );

    write(32'h00aa_00bb, 32'h0000_00000);

    repeat (220000) @( posedge clk );

    write(32'h80cc_00dd, 32'h0000_00000);

    repeat (2500000) @( posedge clk );
    $stop();
  end

i2c_subsystem #(
  .SYS_CLK_FREQ_HZ    ( 25_000_000 ),
  .ADS_ROBOT_READ_EN  ( 1          ),
  .ROBOT_READ_FREQ_HZ ( 100        ),
  .AMM_DATA_WIDTH     ( 32         ),
  .AMM_ADDR_WIDTH     ( 32         )
) dut (
  .clk_i              ( clk        ),
  .srst_i             ( srst       ),
  .csr_if             ( csr_if     ),
  .scl_o              ( scl        ),
  .sda_io             ( sda        ),
  .knob_level_o       ( knob_level )
);

//*****************************************************************************
//*****************************************************************************


task automatic i2c_monitor();
  int i;
  byte tmp;
  enum bit {SGTL,ADS}   device;
  forever
    begin // forever loop
      // Detect START condition
      @(negedge sda iff scl );
      // skip first negedge
      @(negedge scl);

      for( i = 0; i < 8; i++  )
        @( negedge scl ) tmp[7-i] = sda;

      case( tmp ) inside
        8'b0001010? : device = SGTL;
        8'b1001000? : device = ADS;
        default     : $error("Error: unknown device\n");
      endcase

      expect_z();

      case( device )
        SGTL : sgtl_monitor();
        ADS  : ads_monitor();
      endcase
     @( posedge clk );
    end // forever loop
endtask


task automatic expect_z();
  @( negedge scl );
  if( sda != 1'bz )
    $error("Error: expected z state\n");
endtask

task automatic expect_ack();
  @( negedge scl );
    if( sda != 1'b0 )
       $error("Error: expected ACK\n");
endtask

task automatic expect_nack();
  @( negedge scl );
    if( sda != 1'b1 )
       $error("Error: expected NACK\n");
endtask


task automatic sgtl_monitor();
  int i;
  bit rw;
  byte tmp;
  byte addr_byte0, addr_byte1;
  byte data_byte0, data_byte1;

  for( i = 0; i < 8; i++  )
    @( negedge scl ) addr_byte1[7-i] = sda;

  expect_z();

  for( i = 0; i < 8; i++  )
    @( negedge scl ) addr_byte0[7-i] = sda;

  expect_z();

  fork
    @( negedge sda iff scl ) rw = 1;
    @( negedge scl )         rw = 0;
  join_any

  if( rw == 0 )
    begin  // write_monitor
      data_byte1[7] = sda;
      for( i = 0; i < 7; i++  )
        @( negedge scl ) data_byte1[6-i] = sda;

      expect_z();

      for( i = 0; i < 8; i++  )
        @( negedge scl ) data_byte0[7-i] = sda;

      expect_z();

      @( posedge sda iff scl ); // STOP
      $display("SGTL: done i2c WRITE request, address: %4h, data: %4h\n",
                    {addr_byte1,addr_byte0}, {data_byte1, data_byte0});
    end // write_monitor
  else
    begin // read_monitor
      // skip first negedge after restart
      @( negedge scl );
      for( i = 0; i < 8; i++  )
        @( negedge scl ) tmp[7-i] = sda;

      if(tmp[7:1] != 7'b0001010)
        $error("Error: expected SGTL address after restart\n");

      if(tmp[0] != 1'b1)
        $error("Error: expected read request after restart\n");

      expect_z();

      for( i = 0; i < 8; i++ )
        expect_z();

      expect_ack();

      for( i = 0; i < 8; i++ )
        expect_z();

      expect_nack();

      @( posedge sda iff scl ); // STOP
      $display("SGTL: done i2c READ request, address: %4h\n", {addr_byte1,addr_byte0} );
    end // read monitor
endtask


task automatic ads_monitor();
  int i;
  bit rw;
  byte tmp, cmd, data;

  for( i = 0; i < 8; i++  )
    @( negedge scl ) cmd[7-i] = sda;

  expect_z();
  fork
    @( negedge sda iff scl ) rw = 1;
    @( posedge sda iff scl ) rw = 0;
  join_any

  if( rw == 0 )
    begin  // write_monitor
      $display("ADS: done i2s WRITE request, address: %0d, PD : %2b", cmd[6:4], cmd[3:2]);
    end // write_monitor
  else
    begin // read_monitor
      // skip first negedge after restart
      @( negedge scl );
      for( i = 0; i < 8; i++  )
        @( negedge scl ) tmp[7-i] = sda;

      if(tmp[7:1] != 7'b1001000)
        $error("Error: expected ADS address after restart\n");

      if(tmp[0] != 1'b1)
        $error("Error: expected read request after restart\n");

      expect_z();

      for( i = 0; i < 8; i++ )
        expect_z();

      expect_nack();
      @( posedge sda iff scl ); // STOP
      $display("ADS: done i2s READ request, address: %0d\n", cmd[6:4] );
    end // read monitor
endtask

endmodule
