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
