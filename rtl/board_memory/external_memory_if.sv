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

interface external_memory_if #(
  parameter     DATA_WIDTH = 16,
  parameter     ADDR_WIDTH = 21
);
  logic [ADDR_WIDTH-1:0] write_address;
  logic [ADDR_WIDTH-1:0] read_address;
  logic [DATA_WIDTH-1:0] readdata;
  logic [DATA_WIDTH-1:0] writedata;
  logic                  write_enable;
endinterface
