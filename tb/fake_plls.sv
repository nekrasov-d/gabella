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
 * Synthesis-only modules that disguise as pll. They likely won't participate
 * in real clock to clock corner cases simulation, so it's enough for them
 * to just look like the real thing.
 *
 * 12 MHz is taken as the reference. #100000 is one period of 12 MHz
 * clock. So the rest would be
 *   * 25.0    MHz sys clk   ---> 48000
 *   * 11.2896 MHz i2s clk   ---> 106293
 *   * 33.0    MHz sdram clk ---> 36364
 *
 * Make sure it has the same `timescale with tb.sv and 100000 period for
 * 12 MHz clk has not been changed.
 *
 *  -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:37 +0300
 */

`timescale 1ns/1ns

module sys_pll ( input inclk0, output bit c0, locked );
  initial forever #48000 c0 = ~c0;
  initial
    begin
      locked <= 0;
      repeat( 10 ) @( posedge c0 );
      locked <= 1;
    end
endmodule

module i2s_pll ( input inclk0, output bit c0, locked );
  initial forever #106293 c0 = ~c0;
  initial
    begin
      locked <= 0;
      repeat( 10 ) @( posedge c0 );
      locked <= 1;
    end
endmodule

module sdram_pll ( input inclk0, output bit c0, locked );
  initial forever #36364 c0 = ~c0;
  initial
    begin
      locked <= 0;
      repeat( 10 ) @( posedge c0 );
      locked <= 1;
    end
endmodule

