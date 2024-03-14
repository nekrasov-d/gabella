/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * All the interfaces we have in this design
*/


// I2S driver <-------> pins
interface i2s_if;
  logic srst;
  logic mclk;
  logic bclk;
  logic lrclk;
  logic data_from_adc;
  logic data_to_dac;
endinterface


// SDRAM driver <----------> pins
interface sdram_if;
               wire         clk;
               wire         srst;
(* useioff *)  wire  [15:0] dq_i;
(* useioff *)  reg   [13:0] a;
(* useioff *)  reg   [1:0]  bs;
(* useioff *)  reg   [15:0] dq_o;
(* useioff *)  reg          dq_oe;
(* useioff *)  reg   [1:0]  dqm;
(* useioff *)  reg          cs;
(* useioff *)  reg          ras;
(* useioff *)  reg          cas;
(* useioff *)  reg          we;
(* useioff *)  reg          cke;
endinterface


// Memory-consuming audio effects <-----------> SDRAM driver 
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

