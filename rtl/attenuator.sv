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

module attenuator #(
  parameter             DWIDTH = 16,
  parameter             MULT_W = 9
) (
  input signed [DWIDTH-1:0]        data_signed_i,
  input signed [MULT_W-1:0]        mult_i,
  output logic [DWIDTH-1:0] data_o
);

logic signed [DWIDTH+MULT_W-1:0] mult;

assign mult   = data_signed_i * mult_i;
assign data_o = mult >> (MULT_W-1);

endmodule
