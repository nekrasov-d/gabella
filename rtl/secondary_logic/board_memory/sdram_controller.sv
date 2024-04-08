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
 * Low level core to create SDRAM read/write transactions.
 * Based on the Winbond W9864G6JT documentation.
 * though I didn't even try to implement everything, just the very basic
 * stuff to make it work.
 *
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 *
 */

module sdram_controller #(
  parameter           NUM = 4 // Number of independent channels
) (
  sdram_if            sdram,
  input               start_i,
  input        [15:0] writedata_i     [NUM-1:0],
  input        [21:0] write_address_i [NUM-1:0],
  input               write_enable_i  [NUM-1:0],
  input        [21:0] read_address_i  [NUM-1:0],
  output logic [15:0] readdata_o      [NUM-1:0],
  output logic        ready_o
);


localparam TRCD        = 4;
localparam TRP         = 3;

localparam TRC          = 3;
localparam CAS_LAT      = 3;
localparam AR_CYCLE_LEN = 5 + TRC;
localparam CLOSE_LEN    = 5 + TRC;

localparam PTR_WIDTH = $clog2(NUM);

logic [11:0] a;
logic [1:0]  bs;
logic [15:0] dq;
logic        dq_oe;
logic [1:0]  dqm;
logic        cs;
logic        ras;
logic        cas;
logic        we;
logic        cke;

enum logic [2:0] {
  INIT_S,
  IDLE_S,
  AR_CYCLE_S,
  REG_INPUT_S, // Register input data accordng to master pointer
  OPEN_S,  // aka activate row
  WRITE_S,
  READ_S,
  CLOSE_S  // aka precharge
} state, state_next;

logic [21:0]          address;
logic [15:0]          writedata;
logic                 write_enable;
logic [PTR_WIDTH-1:0] ptr;
logic                 write;
logic start;
logic start_pended;
logic last_op;
logic init_done;
logic [11:0] a_init;
logic [3:0]  cmd_init;

// Multi-purpose_counter
logic [3:0] counter;
always_ff @( posedge sdram.clk )
  counter <= state_next != state ? '0 : counter + 1'b1;

//*****************************************************************************
//*****************************************************************************
// Main FSM

always_ff @( posedge sdram.clk )
  if( sdram.srst )
    state <= INIT_S;
  else
    state <= state_next;

always_ff @( posedge sdram.clk )
  if( state==OPEN_S )
    start_pended <= 1'b0;
  else
    if( start_i )
      start_pended <= 1'b1;

assign start = start_i || start_pended;

always_comb
  begin
    state_next = state;
    case( state )
      INIT_S      : if( init_done  )            state_next = IDLE_S;
      IDLE_S      :                             state_next = start ? REG_INPUT_S : IDLE_S;//AR_CYCLE_S;
      AR_CYCLE_S  : if( counter==AR_CYCLE_LEN ) state_next = start ? REG_INPUT_S : IDLE_S;
      REG_INPUT_S :                             state_next = OPEN_S;
      OPEN_S      : if( counter==TRCD)          state_next = write ? WRITE_S : READ_S;
      WRITE_S     :                             state_next = CLOSE_S;
      //READ_S     : if( counter==CAS_LAT )      state_next = CLOSE_S;
      READ_S      :                             state_next = CLOSE_S;
      CLOSE_S     : if( counter==CLOSE_LEN)     state_next = last_op ? IDLE_S : REG_INPUT_S;
      default:;
    endcase
  end

assign ready_o = ( state != INIT_S );
//*****************************************************************************
//*****************************************************************************
// Cycle through arrays of input data with ptr




always_ff @( posedge sdram.clk )
  if( state==IDLE_S )
    write <= 1'b1;
  else
    // If we done last write operation
    if( state==CLOSE_S && ptr=='1 )
      write <= 1'b0;

always_ff @( posedge sdram.clk )
  if( state==IDLE_S )
    ptr <= '0;
  else
    if( state==CLOSE_S && state_next!=CLOSE_S )
      ptr <= ptr + 1'b1;

// register inputs for better timings
always_ff @( posedge sdram.clk )
  if( state==REG_INPUT_S )
    begin
      address      <= write ? write_address_i[ptr] : read_address_i[ptr];
      writedata    <= writedata_i[ptr];
      write_enable <= write_enable_i[ptr];
   end

always_ff @( posedge sdram.clk )
  if( start_i )
    last_op <= 1'b0;
  else
    if( state==READ_S && ptr=='1 )
    last_op <= 1'b1;

//*****************************************************************************
//*****************************************************************************
// init machine

sdram_init sdram_init(
  .clk_i    ( sdram.clk      ),
  .run_i    ( !sdram.srst    ),
  .done_o   ( init_done      ),
  .a_o      ( a_init         ),
  .bs_o     (                ),
  .cmd_o    ( cmd_init       )
);
//*****************************************************************************
//*****************************************************************************
// Wire control

// cs, ras, cas, we

localparam DESELECT     = 4'b1111;
localparam NOP          = 4'b0111;
localparam BANK_ACTIVE  = 4'b0011;
localparam WRITE        = 4'b0100;
localparam READ         = 4'b0101;
localparam PRECHARGE    = 4'b0010;
localparam AUTO_REFRESH = 4'b0001;


logic [3:0] cmd;
assign {cs, ras, cas, we } = cmd;


always_comb
  begin // signal_control
    // defaults (we may set x as well)
    a         = '0;
    bs        = address[21:20];
    dq        = '0;
    dq_oe     = 1'b0;
    dqm       = '0;
    cmd       = DESELECT;
    case( state )
      INIT_S :
        begin
          a      = a_init;
          dqm    = '1;
          cmd    = cmd_init;
        end
      IDLE_S  :;
        // default

      AR_CYCLE_S :

        case( counter )
          'd1     : cmd = DESELECT;
          'd2     : cmd = NOP;
          'd3     : {a[10], cmd} = {1'b1, PRECHARGE}; // precharge all
          'd4     : cmd = NOP;
          'd5     : cmd = AUTO_REFRESH;
          default : cmd = DESELECT;
        endcase

      OPEN_S  :
        begin
          cmd = counter==0 ? BANK_ACTIVE : DESELECT;
          a  = address[19:8];
          bs = address[21:20];
        end

      WRITE_S :
        begin
          cmd    = WRITE;
          a[10]  = 1'b1; // no auto precharge
          a[7:0] = address[7:0];
          dq     = writedata;
          dq_oe  = 1'b1;
          dqm    = write_enable ? '0 : 2'b11;
          bs = address[21:20];
        end
      READ_S  :
        begin
          cmd = counter==0 ? READ : DESELECT;
          a[10]  = 1'b1; // no auto precharge
          a[7:0] = address[7:0];
          bs = address[21:20];
        end
      CLOSE_S :
        case( counter )
          'd1,'d2 : cmd = NOP;
          'd3     : {a[10], cmd} = {1'b1, PRECHARGE}; // precharge all
          'd4     : cmd = NOP;
//          'd5     : cmd = AUTO_REFRESH;
          default : cmd = DESELECT;
        endcase
      default :;
    endcase
  end // signal_control


assign cke = !sdram.srst;

//*****************************************************************************
//*****************************************************************************
// Output registers + catch readdata

always_ff @( posedge sdram.clk )
  begin
    sdram.a     <= {2'b00, a}; // Disable unused banks
    sdram.bs    <= bs;
    sdram.dq_o  <= dq;
    sdram.dq_oe <= dq_oe;
    sdram.dqm   <= dqm;
    sdram.cs    <= cs;
    sdram.ras   <= ras;
    sdram.cas   <= cas;
    sdram.we    <= we;
    sdram.cke   <= cke;
  end

logic [15:0] dq_in /* synthesis ALTERA_ATTRIBUTE = "FAST_INPUT_REGISTER=ON"  */;
always_ff @( posedge sdram.clk )
  dq_in <= sdram.dq_i;

localparam READ_CAPTURE_LAT = 5;

logic [READ_CAPTURE_LAT:0]                read_cmd_d;
logic [READ_CAPTURE_LAT:0][PTR_WIDTH-1:0] ptr_d;

always_ff @( posedge sdram.clk )
  begin
    read_cmd_d <= {read_cmd_d[READ_CAPTURE_LAT-1:0], state==READ_S};
    ptr_d      <= {ptr_d[READ_CAPTURE_LAT-1:0], ptr};
  end

always_ff @( posedge sdram.clk )
  if( read_cmd_d[READ_CAPTURE_LAT] )
    readdata_o[ptr_d[READ_CAPTURE_LAT]] <= dq_in;

endmodule
