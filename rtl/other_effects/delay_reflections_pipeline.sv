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
      primitive_lowpass_filter #(
        .DWIDTH              ( DWIDTH                      ),
        .DEPTH               ( FILTER_DEPTH                )
      ) filter (
        .clk_i               ( clk_i                       ),
        .srst_i              ( srst_i                      ),
        .sample_tick_i       ( sample_tick_i               ),
        .enable_i            ( filter_en_i                 ),
        .data_i              ( data_from_attenuator        ),
        .data_o              ( data_o                      )
      );
    end // gen_filter
  else
    begin : no_filter
      assign data_o = data_from_attenuator;
    end // no_filter
endgenerate

endmodule
