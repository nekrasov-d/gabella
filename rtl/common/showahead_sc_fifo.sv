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
 * This fifo is dedicated to be implemented on registers.
 * This is guaranteed by using synchronous resets in memory initialization,
 * as typical BRAM can't implement this logic.
 * This fifo is always showahead
*/

module showahead_sc_fifo #(
  parameter RAMSTYLE        = "BRAM",
  parameter AWIDTH          = 4,
  parameter DWIDTH          = 16,
  parameter RW_PROTECTED    = 1
) (
  input                     clk_i,
  input                     srst_i,
  input [DWIDTH-1:0]        data_i,
  input                     wr_req_i,
  output logic              empty_o,
  output logic              full_o,
  input                     rd_req_i,
  output logic [DWIDTH-1:0] data_o,
  output logic [AWIDTH:0]   usedw_o
);

logic wr_req;
logic rd_req;

logic [AWIDTH:0] wr_addr;
logic [AWIDTH:0] rd_addr;

assign usedw_o = wr_addr - rd_addr;
assign empty_o = ( usedw_o == '0 );
assign full_o  = ( usedw_o == 2**AWIDTH );

generate
  if( RW_PROTECTED )
    begin
      assign wr_req = wr_req_i && !full_o;
      assign rd_req = rd_req_i && !empty_o;
    end
  else
    begin
      assign wr_req = wr_req_i;
      assign rd_req = rd_req_i;
    end
endgenerate

always_ff @( posedge clk_i )
  if( srst_i )
    wr_addr <= '0;
  else
    if( wr_req )
      wr_addr <= wr_addr + 1'b1;

always_ff @( posedge clk_i )
  if( srst_i )
    rd_addr <= '0;
  else
    if( rd_req )
      rd_addr <= rd_addr + 1'b1;

generate
  case( RAMSTYLE )
    "REGISTERS" :
      begin : dedicated_regs
        logic [2**AWIDTH-1:0][DWIDTH-1:0] mem /* synthesis syn_ramstyle = "registers" */ ;

        always_ff @( posedge clk_i )
          if( srst_i )
            mem <= '0;
          else
            if( wr_req )
              mem[wr_addr[AWIDTH-1:0]] <= data_i;

        assign data_o = mem[rd_addr[AWIDTH-1:0]];
      end // dedicated_regs
    "BRAM" :
      begin : dedicated_bram
        logic [DWIDTH-1:0] mem [2**AWIDTH-1:0]/* synthesis syn_ramstyle="block_ram"*/;

        always_ff @( posedge clk_i )
          if( wr_req )
            mem[wr_addr[AWIDTH-1:0]] <= data_i;

        assign data_o = mem[rd_addr[AWIDTH-1:0]];
      end // dedicated_bram
  endcase
endgenerate

endmodule

