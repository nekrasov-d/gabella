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
 * Top level wrapper for SDRAM controller core. Basically, do unpacking of the
 * data on the system side memory interface (mem_if) and transfer it
 * between sys and sdram clock domains
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 *
 */

module board_memory #(
  parameter       NUM = 16 // Number of independent channels
) (
  // PCB-side interface
  sdram_if                     sdram,
  // Application core side interface
  external_memory_if           mem_if [NUM-1:0],
  input                        sys_clk_i,
  input                        sys_srst_i,

  input                        action_strobe_i, // sound sample
  output logic                 ready_o
);

//*****************************************************************************
//*****************************************************************************
// Data unpack / CDC

logic [15:0] writedata_sys_clk       [NUM-1:0];
logic [21:0] write_address_sys_clk   [NUM-1:0];
logic        write_enable_sys_clk    [NUM-1:0];
logic [21:0] read_address_sys_clk    [NUM-1:0];
logic [15:0] readdata_sys_clk        [NUM-1:0];

logic [15:0] writedata_sdram_clk     [NUM-1:0];
logic [21:0] write_address_sdram_clk [NUM-1:0];
logic        write_enable_sdram_clk  [NUM-1:0];
logic [21:0] read_address_sdram_clk  [NUM-1:0];
logic [15:0] readdata_sdram_clk      [NUM-1:0];

localparam N = $clog2(NUM);

`undef  HIGH_ADDR_IN_LOWER_BITS
`undef  ALL_BANKS_MODE
`define ONE_BANK_MODE

// Unpack interfaces into pipeline registers
genvar i;
generate
  for( i = 0; i < NUM; i++ )
    begin : gen_loop
      always_ff @( posedge sys_clk_i )
        if( action_strobe_i )
          begin
           writedata_sys_clk[i]     <=  mem_if[i].writedata;
           write_enable_sys_clk[i]  <=  mem_if[i].write_enable;
`ifdef HIGH_ADDR_IN_LOWER_BITS
           write_address_sys_clk[i] <= {mem_if[i].write_address, {N{1'b0}}} + i;
           read_address_sys_clk[i]  <= {mem_if[i].read_address,  {N{1'b0}}} + i;
`endif
`ifdef ALL_BANKS_MODE
           write_address_sys_clk[i] <= { i[N-1:0], mem_if[i].write_address[21-N:0] };
           read_address_sys_clk[i]  <= { i[N-1:0], mem_if[i].read_address[21-N:0] };
`endif
`ifdef ONE_BANK_MODE
           write_address_sys_clk[i] <= { 2'b00, i[N-1:0], mem_if[i].write_address[19-N:0] };
           read_address_sys_clk[i]  <= { 2'b00, i[N-1:0], mem_if[i].read_address[19-N:0] };
`endif
         end
      // We don't need an action strobe to show readdata
      always_ff @( posedge sys_clk_i )
        mem_if[i].readdata <= readdata_sys_clk[i];
    end // gen_loop
endgenerate

// Dumb CDC. Don't forget to set false path
always_ff @( posedge sdram.clk )
  begin
    writedata_sdram_clk     <= writedata_sys_clk;
    write_address_sdram_clk <= write_address_sys_clk;
    write_enable_sdram_clk  <= write_enable_sys_clk;
    read_address_sdram_clk  <= read_address_sys_clk;
  end

// We suppose that readdata is used only at action strobes. At the time of the
// next action strobe readdata will be stable for a long time
always_ff @( posedge sys_clk_i )
  readdata_sys_clk <= readdata_sdram_clk;

//*****************************************************************************
//*****************************************************************************
// Action strobe CDC
logic action_strobe;
logic action_strobe_sdram_clk;

localparam SYS_AND_SDRAM_CLK_ARE_THE_SAME = 0;

generate
  if( SYS_AND_SDRAM_CLK_ARE_THE_SAME )
    begin : same_clocks

      assign action_strobe = action_strobe_i;

    end // same_clocks
  else
    begin : differ_clocks
      // Different clocks -> sdram clock is the fastest one
      logic action_strobe_posedge;
      logic [15:0] action_strobe_sdram_clk_d;

      // first cdc this strobe on the faster clock. We may use simple posedge detector
      // as there is at least few sys_clk cycles in one sdram_clk
      always_ff @( posedge sdram.clk )
        action_strobe_sdram_clk <= action_strobe_i;

      assign action_strobe_posedge = action_strobe_i && !action_strobe_sdram_clk;

      // then delay action strobe to ensure that passed through CDC registers data is
      // stable. 16 bit is a random choice
      always_ff @( posedge sdram.clk )
        action_strobe_sdram_clk_d <= { action_strobe_sdram_clk_d[14:0], action_strobe_posedge };

      assign action_strobe = action_strobe_sdram_clk_d[15];
    end // differ_clocks
endgenerate


sdram_controller #(
  .NUM                                    ( NUM                         )
) sdram_controller (
  .sdram                                  ( sdram                       ),
  .start_i                                ( action_strobe               ),
  .writedata_i                            ( writedata_sdram_clk         ),
  .write_address_i                        ( write_address_sdram_clk     ),
  .write_enable_i                         ( write_enable_sdram_clk      ),
  .read_address_i                         ( read_address_sdram_clk      ),
  .readdata_o                             ( readdata_sdram_clk          ),
  .ready_o                                ( ready_o                     )
);

endmodule

