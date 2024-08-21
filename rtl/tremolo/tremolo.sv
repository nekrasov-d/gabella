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
 * Top level module. Contain sine wave generator and two gain stages, one for
 * generated modulation signal, and one for the modulation itself.
 *
 * TD/td is for time detector
 *
 *  -- Dmitry Nekrasov <bluebag@yandex.ru>   Sun, 07 Apr 2024 22:25:55 +0300
*/

module tremolo #(
  // Data width
  parameter DW               = 16,
  parameter TD_MAX_TIME      = 88200, // In samples
  parameter TD_MIN_TIME      = 2024,  // In samples
  parameter TD_TIME_BITWIDTH = $clog2(TD_MAX_TIME)
) (
  input                        clk_i,
  input                        srst_i,
  input                        sample_tick_i,
  input [TD_TIME_BITWIDTH-1:0] td_time_i,
  input                        td_time_change_i,
  input [7:0]                  knob_time_i,
  input [7:0]                  level_i,
  input [7:0]                  mode_i,
  input                        enable_i,
  input signed [DW-1:0]        data_i,
  output logic signed [DW-1:0] data_o
);

//******************************************************************
//**************************** CONTROL *****************************

localparam CONTROL_BY_KNOB = 0;
localparam CONTROL_BY_TD   = 1;

logic control;
logic       reset_phase;
logic [7:0] knob_time_d;
logic [7:0] knob_time_diff;
logic [7:0] knob_time_abs;
logic       knob_change_detected;
logic       knob_change_detected_d;
logic       knob_change_detected_stb;

always_ff @( posedge clk_i )
  knob_time_d <= knob_time_i;

assign knob_time_diff = knob_time_d - knob_time_i;
assign knob_time_abs = knob_time_diff[7] ? ~knob_time_diff : knob_time_diff;
assign knob_change_detected = ( knob_time_abs > 5 );
always_ff @( posedge clk_i )
  knob_change_detected_d <= knob_change_detected;

assign knob_change_detected_stb = knob_change_detected_d && !knob_change_detected;

always_ff @( posedge clk_i )
  if( srst_i )
    control <= CONTROL_BY_KNOB;
  else
    case( control )
      CONTROL_BY_KNOB : if( td_time_change_i         ) control <= CONTROL_BY_TD;
      CONTROL_BY_TD   : if( knob_change_detected_stb ) control <= CONTROL_BY_KNOB;
    endcase

//******************************************************************************
//******************************** MODE PROCESSING *****************************
localparam [0:0] QUARTERS = 0;
localparam [0:0] THIRDS  = 1;

logic [2:0] mode_bits;
logic       pulsation;
logic [1:0] beat_mode /* synthesis keep*/;

assign mode_bits = mode_i[7:5];
assign pulsation = mode_bits[2];
assign beat_mode = mode_bits[1:0];

//******************************************************************************
//************************* PULSATION PERIOD PROCESSING ************************

localparam int PERIOD_BITWIDTH = $clog2( int'( real'(TD_MAX_TIME)/real'(3) + 1 ));

// 1/3 multiplier
logic [TD_TIME_BITWIDTH+10-1:0] td_time_mult;
logic [TD_TIME_BITWIDTH-1:0]    td_time_one_third;
logic [TD_TIME_BITWIDTH-1:0]    td_time_one_quarter;
logic [PERIOD_BITWIDTH-1:0]     period_by_td;
logic [PERIOD_BITWIDTH-1:0]     period_by_knob;
logic [PERIOD_BITWIDTH-1:0]     required_period_in_samples;

assign td_time_mult        = td_time_i * 341; // round( 2**10 / 3 )
assign td_time_one_third   = td_time_mult >> 10;
assign td_time_one_quarter = td_time_i    >> 2;

assign period_by_td = ( pulsation == QUARTERS ) ? td_time_one_quarter : td_time_one_third;

logic [6:0] knob_time_fixed;
assign knob_time_fixed = ( knob_time_i[7:1] == '0 ) ? 7'b0000010 : knob_time_i[7:1];

assign period_by_knob = 2048 * ( knob_time_fixed >> 1 ); // max = 260096

assign required_period_in_samples = ( control == CONTROL_BY_KNOB ) ? period_by_knob :
                                                                     period_by_td;
assign reset_phase = td_time_change_i;

//************************************************************************
//***************************** BEAT TRICKS ******************************

logic       beat;
logic [1:0] beat_cnt;
logic       filter_en;

always_ff @( posedge clk_i )
  if( srst_i || reset_phase || ( pulsation==THIRDS && beat && beat_cnt==2'd2 ) )
    beat_cnt <= '0;
  else
    if( beat )
      beat_cnt <= beat_cnt + 1'b1;


always_comb
  case( { pulsation, beat_mode, beat_cnt } )
    { QUARTERS, 2'b01, 2'b01 } : filter_en = 1;
    { QUARTERS, 2'b01, 2'b10 } : filter_en = 1;
    { QUARTERS, 2'b01, 2'b11 } : filter_en = 1;
    { QUARTERS, 2'b10, 2'b10 } : filter_en = 1;
    { QUARTERS, 2'b10, 2'b11 } : filter_en = 1;
    { QUARTERS, 2'b11, 2'b11 } : filter_en = 1;
    { THIRDS,   2'b01, 2'b01 } : filter_en = 1;
    { THIRDS,   2'b01, 2'b10 } : filter_en = 1;
    { THIRDS,   2'b10, 2'b11 } : filter_en = 1;
    { THIRDS,   2'b11, 2'b10 } : filter_en = 1;
    default                    : filter_en = 0;
  endcase

//************************************************************************
//****************************** MODULATION ******************************

logic [8:0] modulator;

modulation #(
  .PERIOD_BITWIDTH               ( PERIOD_BITWIDTH            )
) mod (
  .clk_i                         ( clk_i                      ),
  .srst_i                        ( srst_i || reset_phase      ),
  .sample_tick_i                 ( sample_tick_i              ),
  .required_period_in_samples_i  ( required_period_in_samples ),
  .beat_o                        ( beat                       ),
  .modulator_o                   ( modulator                  )
);

logic [8:0]  gain /* synthesis keep */;
logic [16:0] mult1;

assign mult1 = ~modulator * level_i;
assign gain = 10'd511 - (mult1 >> 8);

logic signed [DW+9-1:0] mult2;
logic signed [DW-1:0]   enveloped_data;
logic signed [DW-1:0]   filtred_data;
logic signed [DW-1:0]   modulated_data;

assign mult2 = data_i * $signed({1'b0, gain});
assign enveloped_data = mult2 >> 9;

boxcar_filter #(
  .DW                  ( 24                          ),
  .DEPTH               ( 64                          )
) filter (
  .clk_i               ( clk_i                       ),
  .srst_i              ( srst_i                      ),
  .sample_tick_i       ( sample_tick_i               ),
  .data_i              ( enveloped_data              ),
  .data_o              ( filtred_data                )
);

assign modulated_data = filter_en ? filtred_data : enveloped_data;

assign data_o = enable_i ? modulated_data : data_i;

endmodule
