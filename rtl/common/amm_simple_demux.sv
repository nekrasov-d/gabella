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

module amm_simple_demux #(
  parameter BASE_ADDR_0         = 16'h0000,
  parameter BASE_ADDR_1         = 16'h1000,
  parameter SLAVE_ADDR_BIT_MASK = 16'h0fff
  ) (
  avalon_mm_if master_if,
  avalon_mm_if slave_if [1:0]
);

logic sel_0;
logic sel_1;

assign sel_0 = ( master_if.address <  BASE_ADDR_1 );
assign sel_1 = !sel_0;

assign slave_if[0].writedata   = master_if.writedata;
assign slave_if[0].address     = master_if.address & SLAVE_ADDR_BIT_MASK;
assign slave_if[0].write       = sel_0 ? master_if.write : 1'b0;
assign slave_if[0].read        = sel_0 ? master_if.read  : 1'b0;

assign slave_if[1].writedata   = master_if.writedata;
assign slave_if[1].address     = master_if.address & SLAVE_ADDR_BIT_MASK;
assign slave_if[1].write       = sel_1 ? master_if.write : 1'b0;
assign slave_if[1].read        = sel_1 ? master_if.read  : 1'b0;


assign master_if.readdata      = slave_if[0].readdatavalid ? slave_if[0].readdata :
                                                             slave_if[1].readdata;

assign master_if.waitrequest   = sel_0 ? slave_if[0].waitrequest :
                                         slave_if[1].waitrequest;

assign master_if.readdatavalid = slave_if[0].readdatavalid | slave_if[1].readdatavalid;
endmodule
