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

module sin_generator #(
  parameter DWIDTH    = 16,
  parameter SIN_MIF   = "sin.mif",
  parameter RES       = 256,
  parameter FILTER_EN = 0
) (
  input                     clk_i,
  input                     srst_i,
  input                     sample_tick_i,
  input [7:0]               level_i,
  input [$clog2(RES)-1:0]   mult_i,
  input                     mult_en_i,
  output logic [DWIDTH-1:0] data_o
);

logic [$clog2(RES)-1:0] counter;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    case( mult_en_i )
      1'b0 : counter <= counter + 1'b1;
      1'b1 : counter <= counter + mult_i;
    endcase

logic [DWIDTH-1:0] mem_out;
logic [DWIDTH-1:0] data_attenuated;

altsyncram altsyncram_component (
  .address_a      ( counter  ),
  .clock0         ( clk_i    ),
  .q_a            ( mem_out  ),
  .aclr0          (1'b0),
  .aclr1          (1'b0),
  .address_b      (1'b1),
  .addressstall_a (1'b0),
  .addressstall_b (1'b0),
  .byteena_a      (1'b1),
  .byteena_b      (1'b1),
  .clock1         (1'b1),
  .clocken0       (1'b1),
  .clocken1       (1'b1),
  .clocken2       (1'b1),
  .clocken3       (1'b1),
  .data_a         ({32{1'b1}}),
  .data_b         (1'b1),
  .eccstatus      (),
  .q_b            (),
  .rden_a         (1'b1),
  .rden_b         (1'b1),
  .wren_a         (1'b0),
  .wren_b         (1'b0));
defparam
  altsyncram_component.address_aclr_a = "NONE",
  altsyncram_component.clock_enable_input_a = "BYPASS",
  altsyncram_component.clock_enable_output_a = "BYPASS",
  altsyncram_component.init_file = SIN_MIF,
  altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
  altsyncram_component.lpm_type = "altsyncram",
  altsyncram_component.numwords_a = 256,
  altsyncram_component.operation_mode = "ROM",
  altsyncram_component.outdata_aclr_a = "NONE",
  altsyncram_component.outdata_reg_a = "UNREGISTERED",
  altsyncram_component.ram_block_type = "M9K",
  altsyncram_component.widthad_a = 8,
  altsyncram_component.width_a = DWIDTH,
  altsyncram_component.width_byteena_a = 1;


attenuator #(
  .DWIDTH        ( DWIDTH            )
) attenuator (
  .data_signed_i ( mem_out           ),
  .mult_i        ( { 1'b0, level_i } ),
  .data_o        ( data_attenuated   )
);

low_pass_filter #(
  .DWIDTH              ( DWIDTH                      ),
  .DEPTH               ( 16                          )
) filter (
  .clk_i               ( clk_i                       ),
  .srst_i              ( srst_i                      ),
  .sample_tick_i       ( sample_tick_i               ),
  .enable_i            ( FILTER_EN                   ),
  .data_i              ( data_attenuated             ),
  .data_o              ( data_o                      )
);

endmodule

