/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * Simple adder + overflow protection
*/

module sum_sat #(
  parameter DW = 16
) (
  input        signed [DW-1:0] x, y,
  output logic signed [DW-1:0] z
);

logic signed [DW:0] sum;

assign sum = x + y;

always_comb
  case( sum[DW:DW-1] )
    2'b01   : z = {1'b0, {(DW-2){1'b1}}};
    2'b10   : z = {1'b1, {(DW-2){1'b0}}};
    default : z = {sum[DW], sum[DW-2:0]};
  endcase

endmodule
