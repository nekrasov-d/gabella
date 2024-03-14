/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * Basically, a multiplier. But it this project we'd rather need to multiply to
 * 0.xxxx value. It is implemented by right shift. But it shifts not all the way
 * down if OFFSET is > 0. If OFFSET = 1 the output ranges from 0 to data_signed x 2
 * if OFFSET = 2 the output ranges form 0 to data_signed x 4 (with some loss of
 * fractional part precision of course)
*/

module attenuator #(
  parameter             DWIDTH = 16,
  parameter             MULT_W = 9,
  parameter             OFFSET = 1
) (
  input signed [DWIDTH-1:0] data_i,
  input signed [MULT_W-1:0] mult_i,
  output logic [DWIDTH-1:0] data_o
);

localparam MULT_REG_WIDTH = DWIDTH + MULT_W; 

logic signed [DWIDTH+MULT_W-1:0] mult;

assign mult   = data_i * mult_i;
//assign data_o = mult >> (MULT_W-1);
assign data_o = mult[MULT_REG_WIDTH-2 -: DWIDTH];

endmodule
