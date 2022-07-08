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

module delay #(
  parameter           DWIDTH                    = 16,
  // If you have external memory like SDRAM you may use it via
  // external_memory_if turning this parameter on
  parameter           USE_EXTERNAL_MEMORY       = 1,
  // Limits maximum delay time
  parameter           AWIDTH                    = 16,
  // Low pass filter on reflections
  parameter           FILTER_EN                 = 0,
  // Power of 2
  parameter           FILTER_DEPTH              = 16,
  // Low pass filter decrease overall signal level, 
  // this parameter set compensation to make reflections decreasing
  // be felt the same as when we do not use filter
  parameter bit [7:0] FILTER_LEVEL_COMPENSATION = 0,
  // No feedback mode is just taking sample and delaying it,
  // no mixing back (can be used in chorus, for example)
  parameter           NO_FEEDBACK               = 0,
  // this feature mute data from buffer immediately after changing
  // time parameter, then lineary unmute to prevent cut wave cracks
  parameter           UNMUTE_EN                 = 0,
  parameter           UNMUTE_DEPTH              = 16,
  // What pointer to manipulate. Internal stuff for a developer
  parameter           ACTIVE_POINTER            = "READ"
) (
  input               clk_i,
  input               srst_i,
  input               sample_tick_i,
  external_memory_if  external_memory_if,
  input               enable_i,
  input [7:0]         level_i,
  input [AWIDTH-1:0]  time_i,
  input               filter_en_i,
  input [DWIDTH-1:0]        data_i,
  output logic [DWIDTH-1:0] data_o
);

logic [AWIDTH-1:0] wr_addr;
logic [AWIDTH-1:0] rd_addr;
logic [AWIDTH  :0] used_words;
logic              mem_wrreq;
logic              mem_rdreq;
logic              mem_rdaddr;
logic              full;
logic              empty;
logic [DWIDTH-1:0]       mem_wrdata;
logic [DWIDTH-1:0]       mem_rddata;
logic [DWIDTH-1:0]       rddata;

logic [DWIDTH-1:0]       delay;

//***************************************************************************
//***************************************************************************
// Reaction to parameter changing

logic [AWIDTH-1:0] time_d1;
logic              time_changed;
logic              time_reduced;
logic [AWIDTH-1:0] time_diff;

always_ff @( posedge clk_i )
  time_d1 <= time_i;

assign time_changed = ( time_i != time_d1 );

assign time_reduced = ( time_d1 > time_i );

always_ff @( posedge clk_i )
  time_diff <= time_reduced ? time_d1 - time_i : time_i - time_d1;

//***************************************************************************
//***************************************************************************
// Main FSM

enum logic [2:0] {
  IDLE_S,
  INITIAL_FILL_S,
  WORK_S,
  REDUCE_TIME_S,
  INCREASE_TIME_S
} state, state_next;

always_ff @( posedge clk_i )
  if( srst_i )
    state <= IDLE_S;
  else
    state <= state_next;

always_comb
  begin
    state_next = state;
    case( state )
      IDLE_S : state_next = INITIAL_FILL_S;
      INITIAL_FILL_S :
        if( used_words==time_i )
          state_next = WORK_S;
      WORK_S :
         if( time_changed )
            state_next = time_reduced ? REDUCE_TIME_S : INCREASE_TIME_S;
      REDUCE_TIME_S   : state_next = WORK_S;
      INCREASE_TIME_S : state_next = WORK_S;
    endcase
  end

//***************************************************************************
//***************************************************************************
// Memory pointers and aux signals

assign mem_wrreq  = sample_tick_i && !full  && ( state != IDLE_S );
assign mem_rdreq  = sample_tick_i && !empty && ( state != INITIAL_FILL_S );

assign used_words = wr_addr - rd_addr;
assign empty      = ( wr_addr == rd_addr   );
assign full       = ( wr_addr == rd_addr-1 );

generate
  if( ACTIVE_POINTER=="WRITE" )
    begin : manipulate_wr_addr
      always_ff @( posedge clk_i )
        if( srst_i )
          wr_addr <= '0;
        else
          case( state )
            INITIAL_FILL_S, WORK_S :
              case( mem_wrreq )
                1'b0 : wr_addr <= wr_addr;
                1'b1 : wr_addr <= wr_addr + 1'b1;
              endcase
            REDUCE_TIME_S :
              case( mem_wrreq )
                1'b0 : wr_addr <= wr_addr - time_diff;
                1'b1 : wr_addr <= wr_addr - time_diff + 1'b1;
              endcase
            INCREASE_TIME_S :
              case( mem_wrreq )
                1'b0 : wr_addr <= wr_addr + time_diff;
                1'b1 : wr_addr <= wr_addr + time_diff + 1'b1;
              endcase
         endcase

      always_ff @( posedge clk_i )
        if( srst_i )
          rd_addr <= '0;
        else
          if( mem_rdreq )
            rd_addr <= rd_addr + 1'b1;
    end // manipulate_wr_addr
  else
    begin : manipulate_rd_addr
      always_ff @( posedge clk_i )
        if( srst_i )
          wr_addr <= '0;
        else
          if( mem_wrreq )
            wr_addr <= wr_addr + 1'b1;

      always_ff @( posedge clk_i )
        if( srst_i )
          rd_addr <= '0;
        else
          case( state )
            INITIAL_FILL_S, WORK_S :
              case( mem_rdreq )
                1'b0 : rd_addr <= rd_addr;
                1'b1 : rd_addr <= rd_addr + 1'b1;
              endcase
            REDUCE_TIME_S :
              case( mem_rdreq )
                1'b0 : rd_addr <= rd_addr + time_diff;
                1'b1 : rd_addr <= rd_addr + time_diff + 1'b1;
              endcase
            INCREASE_TIME_S :
              case( mem_rdreq )
                1'b0 : rd_addr <= rd_addr - time_diff;
                1'b1 : rd_addr <= rd_addr - time_diff + 1'b1;
              endcase
         endcase
    end // manipulate_rd_addr
endgenerate


//***************************************************************************
//***************************************************************************
// Memory itself

logic mem_rddata_valid;

generate
  if( USE_EXTERNAL_MEMORY )
    begin : use_external_memory
      assign external_memory_if.write_enable  = mem_wrreq;
      assign external_memory_if.write_address = wr_addr;
      assign external_memory_if.writedata     = enable_i ? mem_wrdata : '0;
      assign external_memory_if.read_address  = rd_addr;

      assign mem_rddata = external_memory_if.readdata;

      // readdata will be available only at the next sample_tick
      logic mem_rddata_valid_trigger;
      always_ff @( posedge clk_i )
        if( srst_i )
          mem_rddata_valid_trigger <= 1'b0;
        else
          if( sample_tick_i )
            mem_rddata_valid_trigger <= mem_rdreq;

      assign mem_rddata_valid = mem_rddata_valid_trigger && sample_tick_i;

    end // use_external_memory
  else
    begin : use_block_ram
      logic [DWIDTH-1:0] mem [2**AWIDTH-1:0] /* synthesis syn_ramstyle = "block_ram" */;

      always_ff @( posedge clk_i )
        if( mem_wrreq )
          mem[wr_addr] <= enable_i ? mem_wrdata : '0;

      always @( posedge clk_i )
        if( mem_rdreq )
          mem_rddata <= mem[rd_addr];

      always_ff @( posedge clk_i )
        if( srst_i )
          mem_rddata_valid <= 1'b0;
        else
          if( mem_rdreq )
            mem_rddata_valid <= 1'b1;
    end // use_block_ram
endgenerate

//***************************************************************************
//***************************************************************************
// Post-processing

// Unmite is appliable only if time change is performed via read pointer modification
delay_reflections_pipeline #(
  .DWIDTH                    ( DWIDTH                              ),
  .FILTER_EN                 ( FILTER_EN                           ),
  .FILTER_DEPTH              ( FILTER_DEPTH                        ),
  .FILTER_LEVEL_COMPENSATION ( FILTER_LEVEL_COMPENSATION           ),
  .UNMUTE_EN                 ( UNMUTE_EN && ACTIVE_POINTER=="READ" ),
  .UNMUTE_DEPTH              ( UNMUTE_DEPTH                        )
) refl_pipeline (
  .clk_i                     ( clk_i                               ),
  .srst_i                    ( srst_i                              ),
  .sample_tick_i             ( sample_tick_i                       ),
  .filter_en_i               ( filter_en_i                         ),
  .level_i                   ( level_i                             ),
  .unmute_trigger_i          ( state==WORK_S && time_changed       ),
  .data_i                    ( mem_rddata_valid ? mem_rddata : '0  ),
  .data_o                    ( delay                               )
);

generate
  if( NO_FEEDBACK )
    begin : no_feedback
      assign mem_wrdata = data_i;
      assign data_o     = enable_i ? delay : data_i;
    end // no_feedback
  else
    begin : with_feedback
      assign mem_wrdata = data_i + delay;
      assign data_o     = mem_wrdata;
    end // with_feedback
endgenerate

endmodule
