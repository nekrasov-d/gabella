`include "defines.vh"

module frequency_machine #(
  parameter        INPUT_DW              = 24,
  parameter        OUTPUT_DW             = INPUT_DW,
  parameter string DOWNSAMPLER_INIT_FILE = "",
  parameter string RECOVERY              = "ssidft",
  parameter        WEIRD_MODE_EN         = 0
) (
  input                               clk_i,
  input                               srst_i,
  input                               sample_tick_i,
  input [7:0]                         cutoff_i,
  input [7:0]                         mix_i,
  input                               enable_i,
  input                               bypass_dft_i,
  input                               side_toggle_i,
  input        signed [INPUT_DW-1:0]  data_i,
  output logic signed [OUTPUT_DW-1:0] data_o,
  output logic                        sat_alarm_1_o,
  output logic                        sat_alarm_2_o
);

localparam N  = 4096;
localparam AW = $clog2(N);

logic sample_tick_down;

logic sob, eob;
logic sob_d, eob_d;

logic [23:0] data_down;

logic [15:0] data_floored;
logic [15:0] data_attenuated;

logic [17:0] freq_abs;

//*****************************************************************************

logic silence;

silence_detector #(
  .DW                   ( 24                          ),
  .FLOOR                ( 4080                        )
) sd (
  .clk_i                ( clk_i                       ),
  .srst_i               ( srst_i                      ),
  .sample_tick_i        ( sample_tick_i               ),
  .level_i              ( ~cutoff_i                   ),
  .data_i               ( data_i                      ),
  .silence_o            ( silence                     )
);


downsampler #(
  .DW                   ( 24                          ),
  .DOWNSAMPLE_FACTOR    ( 8                           ),
  .FILTER_TAPS_ROM_FILE ( DOWNSAMPLER_INIT_FILE       )
) downsampler (
  .clk_i                ( clk_i                       ),
  .srst_i               ( srst_i                      ),
  .data_i               ( data_i                      ),
  .sample_tick_i        ( sample_tick_i               ),
  .side_toggle_i        ( side_toggle_i               ),
  .data_o               ( data_down                   ),
  .new_sample_tick_o    ( sample_tick_down            )
);

assign data_floored = data_down[23:8] + `u(data_down[7]);

assign data_attenuated = { {4{data_floored[15]}}, data_floored[14:3] } + `u(data_floored[2]);

logic [11:0] sdft_twiddle_idx;

localparam CW = 18;
logic [CW*2-1:0] sdft_twiddle;

//twiddle_generator_18b #(
//  .DIRECTION   ( "counter clockwise" )
//) sdft_twiddle_generator (
//  .clk_i       ( clk_i                     ),
//  .index_i     ( sdft_twiddle_idx          ),
//  .twiddle_o   ( sdft_twiddle              )
//);

localparam IDW = 18;

localparam string SDFT_TWIDDLE_ROM_FILE = "rtl/frequency_machine/init/twiddles_18b_2048.mem";

logic signed [IDW-1:0] freq_re;
logic signed [IDW-1:0] freq_im;

sdft #(
  .ARCHITECTURE            ( "rl"                        ),
  .N                       ( N                           ),
  .DW                      ( 16                          ),
  .CW                      ( CW                          ),
  .IDW                     ( IDW                         ),
  .IMAG_EN                 ( 1                           ),
  .HANNING_EN              ( 1                           ),
  .SPECTRUM                ( "half"                      ),
  .EXTERNAL_TWIDDLE_SOURCE ( "False"                     ),
  .TWIDDLE_ROM_FILE        ( SDFT_TWIDDLE_ROM_FILE       ),
  .REGISTER_EN             ( 1                           )
) forward (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .sample_tick_i           ( sample_tick_down            ),
  .clear_i                 ( silence | !enable_i         ),
  .data_i                  ( data_attenuated             ),
  .twiddle_idx_o           ( sdft_twiddle_idx            ),
  .twiddle_i               ( sdft_twiddle                ),
  .data_o                  ( { freq_im, freq_re } ),
  .sob_o                   ( sob                         ),
  .eob_o                   ( eob                         ),
  .valid_o                 (                             ),
  .sat_alarm_o             ( sat_alarm_1_o               )
);

vectoring_18b abs (
  .clk_i          ( clk_i                          ),
  .sob_i          ( sob                            ),
  .eob_i          ( eob                            ),
  .x_i            ( freq_re                        ),
  .y_i            ( freq_im                        ),
  .r_o            ( freq_abs                       ),
  .sob_o          ( sob_d                          ),
  .eob_o          ( eob_d                          )
);

logic signed [15:0] data_recovered_normal;
logic signed [15:0] data_recovered_ws1;
logic signed [15:0] data_recovered_ws2;
logic signed [15:0] data_recovered_ssidft;
logic signed [15:0] data_recovered_oscillator;


ssidft #(
  .DW                      ( 18                          ),
  .OW                      ( 16                          ),
  .N                       ( N                           )
) inverse (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .sob_i                   ( sob                         ),
  .eob_i                   ( eob                         ),
  .freq_re_i               ( freq_re                     ),
  .sample_o                ( data_recovered_normal       ),
  .sample_en_o             (                             )
);

logic signed [IDW-1:0] freq_re_abs;
logic signed [IDW-1:0] freq_im_abs;
logic signed [IDW  :0] freq_abs_sum;
logic signed [IDW-1:0] freq_abs_sum_sat;

assign freq_re_abs  = `sign( freq_re ) ? ~freq_re : freq_re;
assign freq_im_abs  = `sign( freq_im ) ? ~freq_im : freq_im;
assign freq_abs_sum = freq_re_abs + freq_im_abs;

sat_sdft #( .IW(19), .OW(18) ) sat_2 ( .x( freq_abs_sum ), .y( freq_abs_sum_sat), .sat_alarm_o ( ) );

ssidft #(
  .DW                      ( 18                          ),
  .OW                      ( 16                          ),
  .N                       ( N                           )
) inverse2 (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .sob_i                   ( sob                         ),
  .eob_i                   ( eob                         ),
  .freq_re_i               ( freq_abs_sum_sat            ),
  .sample_o                ( data_recovered_ws1          ),
  .sample_en_o             (                             )
);


assign data_recovered_ssidft = ( WEIRD_MODE_EN ) ? data_recovered_ws1 :
                                                   data_recovered_normal;


fd_processor #(
  .DW                      ( 18                          ),
  .OW                      ( 24                          ),
  .WEIRD_SOUNDS_EN         ( WEIRD_MODE_EN               )
) fdp (
  .clk_i                   ( clk_i                       ),
  .srst_i                  ( srst_i                      ),
  .sob_i                   ( sob_d                       ),
  .eob_i                   ( eob_d                       ),
  .freq_i                  ( freq_abs                    ),
  .sustain_i               ( level_i                     ),
  .sample_o                ( data_recovered_oscillator   ),
  .alarm_o                 ( sat_alarm_2_o               )
);

logic [23:0] wet;
logic [23:0] wet_filt;
logic [23:0] wet_filt_x4;

assign wet = ( RECOVERY == "oscillator" ) ? { data_recovered_oscillator, 8'h00 } :
                                            { data_recovered_ssidft, 8'h00 };


boxcar_filter #(
  .DW                  ( 24                          ),
  .DEPTH               ( 32                          )
) filter (
  .clk_i               ( clk_i                       ),
  .srst_i              ( srst_i                      ),
  .sample_tick_i       ( sample_tick_i               ),
  .data_i              ( wet                         ),
  .data_o              ( wet_filt                    )
);

assign wet_filt_x4= { wet_filt[23], wet_filt[20:0], 2'b00 };


crossfader #(
  .DWIDTH              ( 24                                 )
) cf (
  .data_1_i            ( data_i                             ),
  .data_2_i            ( side_toggle_i ? wet_filt_x4 : wet  ),
  .level_i             ( mix_i                              ),
  .data_o              ( data_o                             )
);


endmodule

