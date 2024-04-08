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
 * Controlled audio delay module with some enhanced features (like "unmute")
 * Unlkie typical guitar delay, it doesn't pitchshift signal when time is
 * changed during sounding. Instead of this, it just jumps over samples in the
 * buffer, causing glitches that might be smoothed by UNMUTE feature. It creates
 * unique soft switching with some kind of "blooper" vibe. Especially when
 * changed rapidly.
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
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
  parameter           UNMUTE_DEPTH              = 256
) (
  input                     clk_i,
  input                     srst_i,
  input                     sample_tick_i,
  external_memory_if        external_memory_if,
  input                     enable_i,
  input [7:0]               level_i,
  input [AWIDTH-1:0]        time_i,
  input                     filter_en_i,
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
logic [DWIDTH-1:0] mem_wrdata;
logic [DWIDTH-1:0] mem_rddata;
logic [DWIDTH-1:0] rddata;

logic [DWIDTH-1:0] delay;

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
  state <= srst_i ? IDLE_S : state_next;

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
      logic [DWIDTH-1:0] mem [2**AWIDTH-1:0] /* synthesis ramstyle = "M9K" */;

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

delay_reflections_pipeline #(
  .DWIDTH                    ( DWIDTH                              ),
  .FILTER_EN                 ( FILTER_EN                           ),
  .FILTER_DEPTH              ( FILTER_DEPTH                        ),
  .FILTER_LEVEL_COMPENSATION ( FILTER_LEVEL_COMPENSATION           ),
  .UNMUTE_EN                 ( UNMUTE_EN                           ),
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
      sum_sat #( DWIDTH ) sum_output ( data_i, delay, mem_wrdata );
      assign data_o     = enable_i ? mem_wrdata : data_i;
    end // with_feedback
endgenerate

endmodule
