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

interface avalon_st_if #(
  parameter DATA_WIDTH = 16
);

logic [DATA_WIDTH-1:0]   data;
logic                    valid;
logic                    ready;

endinterface
