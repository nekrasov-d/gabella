`include "defines.vh"

module fd_processor #(
  parameter           DW = 16,
  parameter           OW = 24,
  parameter           WEIRD_SOUNDS_EN = 0
) (
  input               clk_i,
  input               srst_i,
  input               sob_i,
  input               eob_i,
  input      [DW-1:0] freq_i, // Real part only
  input         [7:0] sustain_i,
  output logic [15:0] sample_o,
  output logic        alarm_o
);

// Amount of input frequencies = 2**AW
// Nfreq = 8 / AW = 3 example:
//   +----+ sop
// --+    +--------------------------------
//                                      +----+ eop
// -------------------------------------+    +---
// -- ---- ---- ---- ---- ---- ---- ---- ---- --
//   X f0 X f1 X f2 X f3 X f4 X f5 X f6 X f7 X
// -- ---- ---- ---- ---- ---- ---- ---- ---- --

localparam NFREQ = 2048;
localparam AW    = 11;//$clog2(NFREQ);

//*****************************************************************************
// Control

logic [AW-1:0] counter, counter_d;
logic          active, active_d;
logic [1:0]    sob_d, eob_d;

assign active = sob_i | ( counter != '0 );

always_ff @( posedge clk_i )
  if( srst_i )
    counter <= '0;
  else
    if( active )
      counter <= counter + 1'b1;

// Delays
always_ff @( posedge clk_i )
  begin
    counter_d <= counter;
    active_d  <= active;
    sob_d     <= { sob_d[0], sob_i };
    eob_d     <= { eob_d[0], eob_i };
  end

//*****************************************************************************
// Magnitude accumulatior


logic [DW-1:0] freq;
logic [DW-1:0] freq_filt;
logic [DW-1:0] gain_wr;
logic [DW-1:0] gain_wr2;
logic [DW-1:0] gain_rd;
logic [DW+16-1:0] gain_rd_mult;
logic [DW-1:0] gain_rd_attenuated;

localparam FLOOR = 1000;

always_ff @( posedge clk_i )
  freq <= freq_i < FLOOR ? 0 : freq_i;

assign freq_filt = ( counter_d < 50 ) ? '0 : freq;

assign gain_rd_mult = gain_rd * 16'hffff;
assign gain_rd_attenuated = gain_rd_mult >> 16;

assign gain_wr = freq_filt > gain_rd_attenuated ? freq_filt : gain_rd_attenuated;

ram_sdft #(
  .DWIDTH         ( DW                          ),
  .AWIDTH         ( AW                          )
) harmonic_gain (
  .clk            ( clk_i                       ),
  .d              ( gain_wr                     ),
  .wraddr         ( counter_d                   ),
  .wren           ( active_d                    ),
  .rdaddr         ( counter                     ),
  .q              ( gain_rd                     )
);

//*****************************************************************************
// Produce output sample

logic [63:0] acc;
logic [63:0] acc_saved;

always_ff @( posedge clk_i )
  if( counter_d==0 )
    acc <= gain_rd;
  else
    if( counter_d!=0 )
      acc <= acc + gain_rd;

localparam FCW = AW+1;

logic [FCW-1:0] frame_counter;
always_ff @( posedge clk_i )
  if( srst_i )
    frame_counter <= 0;
  else
    if( eob_d[1] )
      frame_counter <= frame_counter + 1'b1;

logic [15:0] sample;

shared_oscillator_accumulator #(
  .DW                     ( DW                          ),
  .AW                     ( AW                          ),
  .FCW                    ( FCW                         ),
  .WEIRD_SOUNDS_EN        ( WEIRD_SOUNDS_EN             )
) intone (
  .clk_i                  ( clk_i                       ),
  .srst_i                 ( srst_i                      ),
  .accumulate_i           ( active_d                    ),
  .save_i                 ( counter_d=='1               ),
  .freq_number_i          ( counter_d                   ),
  .frame_counter_i        ( frame_counter               ),
  .freq_gain_i            ( gain_rd                     ),
  .compression_i          ( 12'hfff                     ),
  .data_o                 ( sample                      ),
  .alarm_o                (                             )
);

assign sample_o = sample;

endmodule

