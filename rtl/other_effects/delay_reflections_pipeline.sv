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

module delay_reflections_pipeline #(
  parameter                 DWIDTH                     = 16,
  parameter                 FILTER_EN                  = 0,
  parameter                 FILTER_DEPTH               = 16,
  parameter bit [7:0]       FILTER_LEVEL_COMPENSATION  = 0,
  parameter                 UNMUTE_EN                  = 0,
  parameter                 UNMUTE_DEPTH               = 256
) (
  input                     clk_i,
  input                     srst_i,
  input                     sample_tick_i,
  input                     filter_en_i,
  input [7:0]               level_i,
  input                     unmute_trigger_i,
  input        [DWIDTH-1:0] data_i,
  output logic [DWIDTH-1:0] data_o
);

logic [DWIDTH-1:0] data_from_attenuator;
logic [7:0]  level_comp;
logic [8:0]  level;
logic [8:0]  unmute;

assign level_comp = FILTER_EN && filter_en_i ? FILTER_LEVEL_COMPENSATION : '0;

assign level = {1'b0, level_i} + level_comp;

always_ff @( posedge clk_i )
  if( srst_i )
    unmute <= 9'h1ff;
  else
    if( UNMUTE_EN && unmute_trigger_i )
      unmute <= '0;
    else
      if( sample_tick_i )
        unmute <= ( unmute < 9'h1ff ) ? unmute + 1'b1 : unmute;

attenuator #(
  .DWIDTH            ( DWIDTH                          )
) attenuator (
  .data_i            ( data_i                          ),
  .mult_i            ( unmute < level ? unmute : level ),
  .data_o            ( data_from_attenuator            )
);

generate
  if( FILTER_EN )
    begin : gen_filter
      logic [DWIDTH-1:0] data_from_filter;

      boxcar_filter #(
        .DW                  ( DWIDTH                      ),
        .DEPTH               ( FILTER_DEPTH                )
      ) filter (
        .clk_i               ( clk_i                       ),
        .srst_i              ( srst_i                      ),
        .sample_tick_i       ( sample_tick_i               ),
        .data_i              ( data_from_attenuator        ),
        .data_o              ( data_from_filter            )
      );
      assign data_o = filter_en_i ? data_from_filter : data_from_attenuator;
    end // gen_filter
  else
    begin : no_filter
      assign data_o = data_from_attenuator;
    end // no_filter
endgenerate

endmodule
