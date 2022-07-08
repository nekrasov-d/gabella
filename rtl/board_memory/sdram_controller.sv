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

module sdram_controller #(
  parameter           NUM = 4
) (
  input               clk_i,
  input               srst_i,

  input               start_i,
  input        [15:0] writedata_i     [NUM-1:0],
  input        [21:0] write_address_i [NUM-1:0],
  input               write_enable_i  [NUM-1:0],
  input        [21:0] read_address_i  [NUM-1:0],
  output logic [15:0] readdata_o      [NUM-1:0],
  output logic        ready_o,

  inout wire   [15:0] dq_io,
  output logic [11:0] a_o   /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */,
  output logic [1:0]  bs_o  /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */,
  output logic [1:0]  dqm_o /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */,
  output logic        cs_o  /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */,
  output logic        ras_o /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */,
  output logic        cas_o /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */,
  output logic        we_o  /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */,
  output logic        cke_o /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */
);


localparam TRCD        = 4;
localparam TRP         = 3;

parameter TRC          = 3;
parameter CAS_LAT      = 3;
parameter AR_CYCLE_LEN = 5 + TRC;
parameter CLOSE_LEN    = 5 + TRC;


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

logic [15:0] dq_reg     /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */;
logic [1:0]  dqm_reg    /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_REGISTER=ON"  */;
logic        dq_oe_reg  /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_ENABLE_REGISTER=ON" */;
logic        dqm_oe_reg /* synthesis ALTERA_ATTRIBUTE = "FAST_OUTPUT_ENABLE_REGISTER=ON" */;

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

logic state_change;
assign state_change = state_next != state;

// Multi-purpose_counter
//`define MAX3(A,B,C) A>B ? (A > C ? A : C) : (B > C ? B : C);
//localparam MAX_PARAMETER = `MAX3(TRCD,CAS_LATENCY,TRP)
//logic [$clog2(MAX_PARAMETER)-1:0] counter;
logic [3:0] counter;
always_ff @( posedge clk_i )
  counter <= state_next != state ? '0 : counter + 1'b1;

logic last_op;
logic init_done;
//*****************************************************************************
//*****************************************************************************
// Main FSM

always_ff @( posedge clk_i )
  if( srst_i )
    state <= INIT_S;
  else
    state <= state_next;

logic start;
logic start_pended;
always_ff @( posedge clk_i )
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

logic [21:0] address;
logic [15:0] writedata;
logic        write_enable;


localparam PTR_WIDTH = $clog2(NUM);

logic [PTR_WIDTH-1:0] ptr;
logic write;

always_ff @( posedge clk_i )
  if( state==IDLE_S )
    write <= 1'b1;
  else
    // If we done last write operation
    if( state==CLOSE_S && ptr=='1 )
      write <= 1'b0;

always_ff @( posedge clk_i )
  if( state==IDLE_S )
    ptr <= '0;
  else
    if( state==CLOSE_S && state_next!=CLOSE_S )
      ptr <= ptr + 1'b1;

// register inputs for better timings
always_ff @( posedge clk_i )
  if( state==REG_INPUT_S )
    begin
      address      <= write ? write_address_i[ptr] : read_address_i[ptr];
      writedata    <= writedata_i[ptr];
      write_enable <= write_enable_i[ptr];
   end

always_ff @( posedge clk_i )
  if( start_i )
    last_op <= 1'b0;
  else
    if( state==READ_S && ptr=='1 )
    last_op <= 1'b1;

//*****************************************************************************
//*****************************************************************************
// init machine
logic [11:0] a_init;
logic [3:0]  cmd_init;

sdram_init sdram_init(
  .clk_i    ( clk_i      ),
  .run_i    ( !srst_i    ),
  .done_o   ( init_done  ),
  .a_o      ( a_init     ),
  .cmd_o    ( cmd_init   )
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


assign cke = !srst_i;

//*****************************************************************************
//*****************************************************************************
// Output registers + catch readdata

always_ff @( posedge clk_i )
  { a_o, bs_o, dq_reg, dq_oe_reg, dqm_o, cs_o, ras_o, cas_o, we_o, cke_o } <=
  { a,   bs,   dq,     dq_oe,     dqm,   cs,   ras,   cas,   we,   cke   };

assign dq_io = dq_oe_reg ? dq_reg : {16{1'bz}};

logic [15:0] dq_in /* synthesis ALTERA_ATTRIBUTE = "FAST_INPUT_REGISTER=ON"  */;
always_ff @( posedge clk_i )
  dq_in <= dq_io;



localparam READ_CAPTURE_LAT = 5;

logic [READ_CAPTURE_LAT:0]                read_cmd_d;
logic [READ_CAPTURE_LAT:0][PTR_WIDTH-1:0] ptr_d;

always_ff @( posedge clk_i )
  begin
    read_cmd_d <= {read_cmd_d[READ_CAPTURE_LAT-1:0], state==READ_S};
    ptr_d      <= {ptr_d[READ_CAPTURE_LAT-1:0], ptr};
  end

always_ff @( posedge clk_i )
  if( read_cmd_d[READ_CAPTURE_LAT] )
    readdata_o[ptr_d[READ_CAPTURE_LAT]] <= dq_in;

endmodule
