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

module limiter #(
  parameter DWIDTH    = 16,
  parameter THRESHOLD = 16000
) (
  input en_i,
  input [DWIDTH-1:0] data_i,
  output logic [DWIDTH-1:0] data_o
);

logic sign;
logic [DWIDTH-2:0] magnitude;
logic [DWIDTH-2:0] magnitude_lim;
logic [DWIDTH-1:0] data_lim;

assign sign = data_i[DWIDTH-1];
assign magnitude = sign ? ~data_i[DWIDTH-2:0] : data_i[DWIDTH-2:0];

assign magnitude_lim = ( magnitude > THRESHOLD ) ? THRESHOLD : magnitude;

assign data_lim = sign ? {1'b1, ~magnitude_lim} : {1'b0, magnitude_lim};

assign data_o = en_i ? data_lim : data_i;

endmodule
