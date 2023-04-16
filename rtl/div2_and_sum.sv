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

module div2_and_sum #(
  parameter DATAW           = 16,
  parameter REGISTER_OUTPUT = 0
)(
  input                    clk_i,
  input        [DATAW-1:0] data1_i,
  input        [DATAW-1:0] data2_i,
  output logic [DATAW-1:0] data_o
);

logic [DATAW-1:0] data1_div;
logic [DATAW-1:0] data2_div;
logic [DATAW-1:0] sum;

assign data1_div = data1_i[DATAW-1] ? {2'b11, data1_i[DATAW-2:1]} :
                                      {2'b00, data1_i[DATAW-2:1]};

assign data2_div = data2_i[DATAW-1] ? {2'b11, data2_i[DATAW-2:1]} :
                                      {2'b00, data2_i[DATAW-2:1]};

assign sum = data1_div + data2_div;

generate
  if( REGISTER_OUTPUT )
    begin : reg_output
      always_ff @( posedge clk_i )
        data_o <= sum;
    end // reg_output
  else
    begin : comb_output
      assign data_o = sum;
    end
endgenerate
endmodule


