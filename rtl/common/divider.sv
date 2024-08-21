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
 * Unsigned var/var divider. The idea was picked in the "Advanced Synthesis
 * Cookbook" by Altera (v11.0 2011). Unlike a pipelined one which can receive 1
 * value pair by clock cycle, this one locks in a busy state for NBITS cycles.
 * I wanted to keep the interface just as simple as I needed. So there's no
 * precise 'valid' indication and backpressure. It is supposed that numerator
 * and denominator change rather slowly, and the module just quietly follows
 * these changes, updating output values after NBITS tacts
 *
 * XXX: verification was too cursory
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 19 Aug 2024 22:46:32 +0300
 */

`define sign(X) X[$bits(X)-1]


module divider #(
  parameter MAX_VAL = 32,
  parameter NBITS   = 0 // XXX : Quartis does not support $onehot() (FUCK!!!! WHY????),
                        // so you have to calculate it outside
  //parameter int NBITS   = $onehot( MAX_VAL ) ? $clog2(MAX_VAL) + 1 : $clog2(MAX_VAL)
) (
  input                    clk_i,
  input                    srst_i,
  input                    valid_i,
  input        [NBITS-1:0] numerator_i,
  input        [NBITS-1:0] denominator_i,
  output logic [NBITS-1:0] quotient_o,
  output logic [NBITS-1:0] remainder_o // XXX: this output seems wrong, idk why
);

logic                     done;
logic                     start;
logic                     in_progress;
logic [NBITS-1:0]         numerator_reg;
logic [NBITS-1:0]         denominator_reg;
logic [NBITS-1:0]         workspace;
logic [NBITS-1:0]         diff;
logic [NBITS-1:0]         quotient;
logic [$clog2(NBITS)-1:0] counter;

// I think this control logic ( start / in_progress / done ) could be more clear
// and strightforward, I just can't be bothered to rethink it

assign start = ( valid_i && !in_progress ) || ( valid_i && in_progress && done );

always_ff @( posedge clk_i )
  if( srst_i )
    in_progress <= 1'b0;
  else
    if( start )
      in_progress <= 1'b1;
    else
      if( done )
        in_progress <= 1'b0;

always_ff @( posedge clk_i )
  if( srst_i || start || done )
    counter <= '0;
  else
    if( !done )
      counter <= counter + 1'b1;

assign done = ( counter == NBITS );

always_ff @( posedge clk_i )
  if( srst_i )
    { numerator_reg, denominator_reg } <= '0;
  else
    if( start )
      { numerator_reg, denominator_reg } <= { numerator_i, denominator_i };

assign diff = workspace - denominator_reg;

always_ff @( posedge clk_i )
  if( srst_i || start )
    workspace <= 0;
  else
    if( in_progress )
      workspace <= `sign(diff) ? { workspace[NBITS-2:0], numerator_reg[NBITS-1] } :
                                 {      diff[NBITS-2:0], numerator_reg[NBITS-1] };

always_ff @( posedge clk_i )
  if( srst_i )
    quotient <= '0;
  else
    if( in_progress && !done )
      quotient <= { quotient[NBITS-2:0], !`sign(diff) };


always_ff @( posedge clk_i )
  if( done )
    begin
      quotient_o  <= quotient;
      remainder_o <= workspace >> 1;
    end

endmodule
