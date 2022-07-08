/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 * XXX: add annotation
*/

interface avalon_mm_if #(
  parameter DATA_WIDTH = 16,
  parameter ADDR_WIDTH = 16
);

logic [DATA_WIDTH-1:0]   writedata;
logic [DATA_WIDTH-1:0]   readdata;
logic [DATA_WIDTH/8-1:0] byteenable;
logic [ADDR_WIDTH-1:0]   address;
logic                    write;
logic                    read;
logic                    readdatavalid;
logic                    waitrequest;

logic burstcount;

endinterface
