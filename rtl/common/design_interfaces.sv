/*
 * MIT License
 *
 * Copyright (c) 2024 Dmitriy Nekrasov
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * ---------------------------------------------------------------------------------
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 *
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

