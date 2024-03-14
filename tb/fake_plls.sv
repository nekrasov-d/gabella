/*
 * Copyright (C) 2024 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * ---------------------------------------------------------------------------
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

