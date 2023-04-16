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

module reverb #(
  parameter           NUM                   = 8,
  parameter reverb_pkg::reverb_refl_time_t DELAYS = '{default:0},
  parameter           MAX_REFLECTION_LENGTH = 8191,
  parameter           DWIDTH                = 16,
  parameter           AWIDTH                = $clog2(MAX_REFLECTION_LENGTH),
  parameter           FILTER_EN             = 1,
  parameter           FILTER_DEPTH          = 16,
  parameter           CHORUS_EN             = 1,
  parameter           PRE_DELAY_EN          = 1,
  parameter           MAX_PRE_DELAY         = 8191,

  parameter           POST_DELAY_NUM        = 1
) (
  input               clk_i,
  input               srst_i,
  input               sample_tick_i,
  input               enable_i,

  external_memory_if  main_memory_if,
  external_memory_if  post_delay_0_memory_if,
  external_memory_if  post_delay_1_memory_if,
  external_memory_if  post_delay_2_memory_if,
  external_memory_if  post_delay_3_memory_if,

  input [7:0]         post_delay_enable_i,

  input [7:0]         post_delay_level_i,

  input [7:0]         level_i,
  input [7:0]         mix_i,
  input [15:0]        pre_delay_i,
  input [DWIDTH-1:0]        data_i,
  output logic [DWIDTH-1:0] data_o
);

localparam USE_EXTERNAL_MEMORY = 0;

//**************************************************************************
//**************************************************************************
// Checking

// synopsys translate_off
initial
  begin
    int i;
    foreach( NUM[i] )
      if( NUM[i] > MAX_REFLECTION_LENGTH ) $error( "Error: wrong reflection end" );
    if( pre_delay_i > MAX_PRE_DELAY ) $error( "Error: wrong pre-delay setup ");
  end
// synopsys translate_on



//***************************************************************************
//***************************************************************************
// Pre-processing

logic [DWIDTH-1:0] data_pre_delay;
logic [DWIDTH-1:0] data_hipass;
logic [15:0] refl_sum_attenuation;
logic [DWIDTH-1:0] data_to_filter;

generate
  if( PRE_DELAY_EN )
    begin : gen_pre_delay
      delay #(
        .DWIDTH        ( DWIDTH ),
        .USE_EXTERNAL_MEMORY ( 0 ),
        .AWIDTH        ( $clog2(MAX_PRE_DELAY) ),
        .FILTER_EN     ( 0                     ),
        .NO_FEEDBACK   ( 1                     )
      ) pre_delay (
        .clk_i         ( clk_i                 ),
        .srst_i        ( srst_i                ),
        .sample_tick_i ( sample_tick_i         ),
        .enable_i      ( 1'b1                  ),
        .level_i       ( 8'd255                ),
        .time_i        ( pre_delay_i           ),
        .data_i        ( data_i                ),
        .filter_en_i   ( 1'b0                  ),
        .data_o        ( data_pre_delay        )
      );
    end // gen_pre_delay
  else
    begin : no_pre_delay
      assign data_pre_delay = data_i;
    end // no_pre_delay
endgenerate

logic [DWIDTH-1:0] foo, bar;


ram_fir #(
  .DWIDTH        ( DWIDTH                      ),
  .LEN           ( 511                         ),
  .COEFFS_FILE   ( "../ram_fir/fir_coeffs.mif"    )
) hipass1 (
  .clk_i         ( clk_i                       ),
  .srst_i        ( srst_i                      ),
  .sample_tick_i ( sample_tick_i               ),
  .data_i        ( data_i              ),
  //.data_o        ( data_hipass                 )
  .data_o        ( foo                         )
);

ram_fir #(
  .DWIDTH        ( DWIDTH                      ),
  .LEN           ( 511                         ),
  .COEFFS_FILE   ( "../ram_fir/fir_coeffs.mif"    )
) hipass2 (
  .clk_i         ( clk_i                       ),
  .srst_i        ( srst_i                      ),
  .sample_tick_i ( sample_tick_i               ),
  .data_i        ( foo              ),
  //.data_o        ( data_hipass                 )
  .data_o        ( bar                         )
);

assign data_o = enable_i ? bar : data_i;


//***************************************************************************
//***************************************************************************
// Generate state machines, each one for one reflection

logic [AWIDTH-1:0] wr_addr;
logic [AWIDTH-1:0] rd_addr_local [NUM-1:0];
logic [NUM-1:0]    refl_ready;

logic [NUM-1:0] mem_rdreq;
logic [NUM-1:0] mem_rdreq_d1;
logic [NUM-1:0] mem_rdreq_d2;

typedef enum logic [2:0] {
  IDLE_S,
  INITIAL_FILL_S,
  WORK_S
} state_t;

genvar i;
generate
  for( i = 0; i < NUM; i++ )
    begin : gen_refl_machines

      state_t state, state_next;

      logic [AWIDTH:0] usedw;

      assign usedw = wr_addr - rd_addr_local[i];

      always_ff @( posedge clk_i )
        if( srst_i )
          state <= IDLE_S;
        else
          state <= state_next;

      always_comb
        begin
          state_next = state;
          case( state )
            IDLE_S         : if( enable_i )         state_next = INITIAL_FILL_S;
            INITIAL_FILL_S : if( usedw==DELAYS[i] ) state_next = WORK_S;
            WORK_S         : if( !enable_i )        state_next = IDLE_S;
            default        :;
          endcase
        end

     assign refl_ready[i] = ( state == WORK_S );

     always_ff @( posedge clk_i )
       if( srst_i )
         rd_addr_local[i] <= '0;
       else
         if( mem_rdreq[i] )
           rd_addr_local[i] <= rd_addr_local[i] + 1'b1;
    end // gen_refl_machines
endgenerate

//***************************************************************************
//***************************************************************************
// Writing routine


logic [DWIDTH-1:0] feedback_data;

logic mem_wrreq;
logic [AWIDTH-1:0] rd_addr;
logic [DWIDTH-1:0] mem_rddata;
logic [DWIDTH-1:0] mem_rddata_local [NUM-1:0];




assign mem_wrreq = sample_tick_i && enable_i;

always_ff @( posedge clk_i )
  if( srst_i )
    wr_addr <= '0;
  else
    if( mem_wrreq )
      wr_addr <= wr_addr + 1'b1;

generate
  if( USE_EXTERNAL_MEMORY )
    begin : external_mem
      assign main_memory_if.write_enable  = mem_wrreq;
      assign main_memory_if.write_address = wr_addr;
      assign main_memory_if.writedata     = feedback_data;

      assign main_memory_if.read_address = rd_addr_local[rd_counter];
      assign mem_rddata                  = main_memory_if.readdata;

    end // external_mem
  else
    begin : internal_mem

      logic [DWIDTH-1:0] mem [2**AWIDTH-1:0] /* synthesis syn_ramstyle = "block_ram"*/;

      always_ff @( posedge clk_i )
        if( mem_wrreq )
          mem[wr_addr] <= feedback_data;


      always @( posedge clk_i )
        mem_rddata <= mem[rd_addr];

    end // internal_mem
endgenerate

//***************************************************************************
//***************************************************************************
// Reading routine

logic [$clog2(NUM)-1:0] rd_counter;

logic read_cycle_en;


always_ff @( posedge clk_i )
  if( srst_i )
    rd_counter <= '0;
  else
    if( rd_counter == NUM )
      rd_counter <= '0;
    else
      if( read_cycle_en )
        rd_counter <= rd_counter + 1'b1;

always_ff @( posedge clk_i )
  if( srst_i )
    read_cycle_en <= 1'b0;
  else
    if( rd_counter == NUM-1 )
      read_cycle_en <= 1'b0;
    else
      if( sample_tick_i )
        read_cycle_en <= 1'b1;

always_comb
  for( int j = 0; j < NUM; j++ )
    mem_rdreq[j] = ( read_cycle_en && refl_ready[j] && ( rd_counter == j ) );

always_ff @( posedge clk_i )
  begin
    mem_rdreq_d1 <= mem_rdreq;
    mem_rdreq_d2 <= mem_rdreq_d1;
  end

always_ff @( posedge clk_i )
  rd_addr <= rd_addr_local[rd_counter];


always_ff @( posedge clk_i )
  for( int j = 0; j < NUM; j++ )
    if( srst_i )
      mem_rddata_local[j] <= '0;
    else
      if( mem_rdreq_d2[j] )
        mem_rddata_local[j] <= mem_rddata;

//*****************************************************************************
//*****************************************************************************
// Readdata processing

localparam SUM_LOOPS = $clog2(NUM);

localparam EXT_BITS = 2;

logic [DWIDTH-1+EXT_BITS:0] tmp [SUM_LOOPS:0][NUM-1:0];
logic [DWIDTH-1+EXT_BITS:0] refl_sum;

always_comb
  for( int i = 0; i < NUM; i++ )
    tmp[0][i] = mem_rddata_local[i][DWIDTH-1] ?
                { mem_rddata_local[i], {EXT_BITS{1'b1}} } :
                { mem_rddata_local[i], {EXT_BITS{1'b0}} };

genvar j, k;
generate
  for( j = 0; j < SUM_LOOPS; j++ )
    begin : sum_loop
      for( k = 0; k < NUM/(2*(j+1)); k++ )
        begin : gen_summators
          div2_and_sum #(
            .DATAW           ( 16+EXT_BITS   ),
            .REGISTER_OUTPUT ( 0             )
          ) sum_reflections(
            .clk_i           ( clk_i         ),
            .data1_i         ( tmp[j][2*k]   ),
            .data2_i         ( tmp[j][2*k+1] ),
            .data_o          ( tmp[j+1][k]   )
          );
        end // gen_summators
    end // sum_loop
endgenerate

assign refl_sum = tmp[SUM_LOOPS][0];

//***************************************************************************
// FEEDBACK

// Reduce bits to keep feedback gain level less than 1, keep sign
assign refl_sum_attenuation = refl_sum[DWIDTH-1+EXT_BITS] ?
                                  {1'b1, refl_sum[DWIDTH-2+EXT_BITS:EXT_BITS]} :
                                  {1'b0, refl_sum[DWIDTH-2+EXT_BITS:EXT_BITS]};


sum_sat #( DWIDTH ) mix_fb ( refl_sum_attenuation, data_chorus, feedback_data );

//generate
//  if( FILTER_EN )
//    begin : gen_filter
//      low_pass_filter #(
//        .DWIDTH            ( DWIDTH               ),
//        .DEPTH             ( FILTER_DEPTH         )
//      ) filter (
//        .clk_i             ( clk_i                ),
//        .srst_i            ( srst_i               ),
//        .sample_tick_i     ( sample_tick_i        ),
//        .enable_i          ( 1'b1                 ),
//        .data_i            ( data_to_filter       ),
//        .data_o            ( feedback_data        )
//      );
//    end // gen_filter
//  else
//    begin : no_filter
//      assign feedback_data = data_to_filter;
//    end // no_filter
//endgenerate

//***************************************************************************
// OUTPUT

logic [DWIDTH-1:0] wet;

assign wet = refl_sum[DWIDTH-1+EXT_BITS] ? { 1'b1, refl_sum[DWIDTH-2:0] } :
                                           { 1'b0, refl_sum[DWIDTH-2:0] };


logic [DWIDTH-1:0] post_delay_wet;

//post_delay post_delay #(
//  .DWIDTH              ( DWIDTH                                ),
//  .POST_DELAY_TIME     ( POST_DELAY_TIME                       ),
//  .USE_EXTERNAL_MEMORY ( USE_EXTERNAL_MEMORY                   )
//) post_delay (
//  .clk_i                ( clk_i                                ),
//  .srst_i               ( srst_i                               ),
//  .sample_tick_i        ( sample_tick_i                        ),
//  .external_memory_0_if ( post_delay_0_memory_if               ),
//  .external_memory_1_if ( post_delay_1_memory_if               ),
//  .external_memory_2_if ( post_delay_2_memory_if               ),
//  .external_memory_3_if ( post_delay_3_memory_if               ),
//  .data_i               ( wet                                  ),
//  .data_o               ( post_delay_wet                       )
//);


//crossfader #(
//  .DWIDTH             ( DWIDTH                )
//) mix_output (
//  .data_1_i           ( data_i                ),
//  .data_2_i           ( post_delay_wet        ),
//  .level_i            ( enable_i ? mix_i : '0 ),
//  .data_o             ( data_o                )
//);

endmodule
