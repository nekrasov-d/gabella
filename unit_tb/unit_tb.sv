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
 * See README
*/

`timescale 1ns/1ns

module unit_tb;

localparam SYS_FREQ    = 4_000_000; // Slower than the real one to reduce simulation time
localparam SAMPLE_FREQ = 44_100;

localparam CLOCLS_IN_ONE_SAMPLE_TICK = $ceil(SYS_FREQ/SAMPLE_FREQ);

bit clk;
bit srst;

always #1 clk = ~clk;

initial
  begin
    @( posedge clk );
    srst = 1;
    @( posedge clk );
    srst = 0;
  end

default clocking cb @( posedge clk );
endclocking

mailbox data_mbx;
int count;

//*****************************************************************************
//*****************************************************************************
// Utility tasks

task automatic file_to_mailbox( mailbox mbx, string input_file );
  int fd;
  string data;
  fd = $fopen(input_file, "r");
  if(!fd) $fatal("can't open input file");
  while( !$feof(fd) )
    begin
      $fgets( data, fd );
      case( data.len( ) )
        // This must be a  file with 16-bit encoded data, attach bottom zero bits
        // Yes, if the value is negative they should be 1, but it's not a big deal
        // +1 is for EOL; TODO : more checking
        4+1       : data = {data, "00"};
        6+1       :;
        default : $error("Invalid sound sample");
      endcase
      mbx.put( data );
      count++;
    end
  $fclose(fd);
endtask


function automatic bit [23:0] string_cast( string input_string );
  for( int i = 0; i < 6; i++ )
    begin
      case( input_string[i] )
        "0" : string_cast += ( 4'h0 << 4*(5-i) );
        "1" : string_cast += ( 4'h1 << 4*(5-i) );
        "2" : string_cast += ( 4'h2 << 4*(5-i) );
        "3" : string_cast += ( 4'h3 << 4*(5-i) );
        "4" : string_cast += ( 4'h4 << 4*(5-i) );
        "5" : string_cast += ( 4'h5 << 4*(5-i) );
        "6" : string_cast += ( 4'h6 << 4*(5-i) );
        "7" : string_cast += ( 4'h7 << 4*(5-i) );
        "8" : string_cast += ( 4'h8 << 4*(5-i) );
        "9" : string_cast += ( 4'h9 << 4*(5-i) );
        "a" : string_cast += ( 4'ha << 4*(5-i) );
        "b" : string_cast += ( 4'hb << 4*(5-i) );
        "c" : string_cast += ( 4'hc << 4*(5-i) );
        "d" : string_cast += ( 4'hd << 4*(5-i) );
        "e" : string_cast += ( 4'he << 4*(5-i) );
        "f" : string_cast += ( 4'hf << 4*(5-i) );
        default : string_cast = 0;
      endcase
    end
endfunction

bit [23:0] data_to_rtl;
bit        sample_tick;

task automatic get_content_and_convert( mailbox mbx, ref bit [23:0] data,
                                        ref bit valid, input int gap );
  string data_as_string;
  while( mbx.num() > 0 )
    begin
      mbx.get( data_as_string );
      data = string_cast( data_as_string );
      valid = 1;
      ##1;
      valid = 0;
      ##( gap-1 );
    end
endtask

//*****************************************************************************
//*****************************************************************************
// Main loop

initial
  begin : main
    int count;
    data_mbx = new();
    data_mbx.put( "000000" );
    file_to_mailbox(data_mbx, `INPUT_FILE);
    fork
      get_content_and_convert( data_mbx, data_to_rtl, sample_tick, CLOCLS_IN_ONE_SAMPLE_TICK );
    join_any
    $display("%0d", count);
    $stop;
  end

//*****************************************************************************
//*****************************************************************************


localparam DATA_WIDTH = 24; // or 16

bit [DATA_WIDTH-1:0] data_in;
assign data_in = data_to_rtl[23:(24-DATA_WIDTH)]; // [23:0] or [23:8];

generate
  if( `DUT == "swell" )
    begin : sim_swell
      swell #(
        .DWIDTH         ( DATA_WIDTH                  )
      ) swell (
        .clk_i          ( clk                         ),
        .srst_i         ( srst                        ),
        .sample_tick_i  ( sample_tick                 ),
        .enable_i       ( 1'b1                        ),
        .noise_floor_i  ( 'd300                       ),
        .threshold_i    ( 'd1000                      ),
        .data_i         ( data_in                     ),
        .data_o         (                             )
      );
  end // sim_swell
endgenerate

generate
  if( `DUT == "filter" )
    begin : sim_filter
      low_pass_filter #(
        .DWIDTH        ( DATA_WIDTH      ),
        .DEPTH         ( 32              )
      ) filter (
        .clk_i         ( clk             ),
        .srst_i        ( srst            ),
        .sample_tick_i ( sample_tick     ),
        .enable_i      ( 1'b1            ),
        .data_i        ( data_in         ),
        .data_o        (                 )
      );
  end // sim_filter
endgenerate

generate
  if( `DUT == "delay" )
    begin : sim_delay
      bit [15:0] delay_time;
      initial
        begin
          delay_time = 16'd10 << 8;
          repeat (50_000) @( posedge sample_tick );
          delay_time = 16'd25 << 8;
          repeat (25_000) @( posedge sample_tick );
          delay_time = 16'd64 << 8;
        end

      external_memory_if #(
        .DATA_WIDTH ( main_config::DATA_WIDTH     ),
        .ADDR_WIDTH ( main_config::MEM_ADDR_WIDTH )
      ) mem_if ();

      delay #(
        .DWIDTH                    ( DATA_WIDTH        ),
        .USE_EXTERNAL_MEMORY       ( 0                 ),
        .AWIDTH                    ( 16                ),
        .FILTER_EN                 ( 1                 ),
        .FILTER_DEPTH              ( 16                ),
        .FILTER_LEVEL_COMPENSATION ( 16                ),
        .NO_FEEDBACK               ( 0                 ),
        .UNMUTE_EN                 ( 1                 )
      ) delay (
        .clk_i                     ( clk               ),
        .srst_i                    ( srst              ),
        .sample_tick_i             ( sample_tick       ),
        .external_memory_if        ( mem_if            ),
        .enable_i                  ( 1'b1              ),
        .level_i                   ( 8'd255            ),
        .time_i                    ( delay_time        ),
        .filter_en_i               ( 1'b1              ),
        .data_i                    ( data_in           ),
        .data_o                    (                   )
      );
   end // sim_delay
endgenerate

generate
  if( `DUT == "chorus" )
    begin : sim_chorus
      chorus #(
        .MIN_TIME         ( 'h370                       ),
        .MAX_TIME         ( 'h530                       )
      ) chorus (
        .clk_i            ( clk                         ),
        .srst_i           ( srst                        ),
        .sample_tick_i    ( sample_tick                 ),
        .enable_i         ( 1'b1                        ),
        .level_i          ( 8'd255                      ),
        .max_time_i       (                             ),
        .depth_i          ( 8'h80                       ),
        .data_i           ( data_in                     ),
        .data_o           (                             )
      );
   end // sim_chorus
endgenerate

//*****************************************************************************


generate
  if( `DUT == "reverb" )
    begin : sim_reverb

      initial $fatal( "Can't simulate reverb now" );
      /*
      reverb #(
        .NUM           ( reverb_pkg::NUM       ),
        .DELAYS        ( reverb_pkg::DELAYS    ),
        .FILTER_EN     ( 0                     ),
        .FILTER_DEPTH  ( 8                     ),
        .CHORUS_EN     ( 0                     ),
        .PRE_DELAY_EN  ( 1                     )
      ) reverb (
        .clk_i         ( clk                   ),
        .srst_i        ( srst                  ),
        .sample_tick_i ( sample_tick           ),
        .enable_i      ( 1'b1                  ),
        .level_i       ( 8'd255                ),
        .pre_delay_i   ( 16'd8000              ),
        .mix_i         ( 8'd255                ),
        .data_i        ( data_in               ),
        .data_o        (                       )
      );
      */
    end // sim_reverb
endgenerate

endmodule
