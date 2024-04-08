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
        logic [2**AWIDTH-1:0][DWIDTH-1:0] mem /* synthesis ramstyle = "logic" */ ;

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
        logic [DWIDTH-1:0] mem [2**AWIDTH-1:0] /* synthesis ramstyle="M9K" */;

        always_ff @( posedge clk_i )
          if( wr_req )
            mem[wr_addr[AWIDTH-1:0]] <= data_i;

        assign data_o = mem[rd_addr[AWIDTH-1:0]];
      end // dedicated_bram
  endcase
endgenerate

endmodule

