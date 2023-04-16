/*
 * Copyright (C) 2021 Dmitriy Nekrasov
 *
 * This work is free. You can redistribute it and/or modify it under the
 * terms of the Do What The Fuck You Want To Public License, Version 2,
 * as published by Sam Hocevar. See the COPYING file or http://www.wtfpl.net/
 * for more details.
 *
 * Boss slow gear analog.
 * Rather broken than not
 * XXX: add annotation
*/

module swell #(
  parameter                 DWIDTH = 16
) (
  input                     clk_i,
  input                     srst_i,
  input                     sample_tick_i,
  input                     enable_i,
  input [DWIDTH-1:0]        noise_floor_i,
  input [DWIDTH-1:0]        threshold_i,
  input [DWIDTH-1:0]        data_i,
  output logic [DWIDTH-1:0] data_o
);

localparam THRESHOLD = 10;

logic [DWIDTH-2:0] magnitude;
assign magnitude = data_i[DWIDTH-1] ? ~data_i[DWIDTH-2:0] : data_i[DWIDTH-2:0];

logic [31:0] integrator;
logic [THRESHOLD-1:0] counter;
logic [DWIDTH-2:0] envelope;
logic [DWIDTH-2:0] envelope_d1;
logic attack_detected;

always_ff @( posedge clk_i )
  if( srst_i )
    counter <= '0;
  else
    if( sample_tick_i )
      counter <= counter + 1'b1;

always_ff @( posedge clk_i )
  if( srst_i )
    integrator <= '0;
  else
    if( sample_tick_i )
      integrator <= (counter == '1) ? magnitude : integrator + magnitude;

always_ff @( posedge clk_i )
  if( sample_tick_i && counter == '1 )
    begin
      envelope    <= integrator[DWIDTH-2+THRESHOLD-1:THRESHOLD];
      envelope_d1 <= envelope;
    end

enum logic [1:0] {
  SUB_ATTACK_S,
  PASS_S,
  ATTACK_S,
  SILENCE_S
} state, state_next;

parameter SWELL_DEPTH = 14;

logic [SWELL_DEPTH:0] attack_counter;

logic [SWELL_DEPTH:0] value;

logic [DWIDTH-2:0] envelope_incr;

assign envelope_incr = (envelope > envelope_d1 ) ? envelope - envelope_d1 : 0;


always_ff @( posedge clk_i )
  if( srst_i || !enable_i )
    state <= SILENCE_S;
  else
    state <= state_next;


assign attack_detected = ( envelope > ( envelope_d1 + threshold_i ) );

always_comb
  begin
    state_next = state;
    case( state )
      SILENCE_S    : if( attack_detected )      state_next = ATTACK_S;
      ATTACK_S     : if( attack_counter == '1 ) state_next = PASS_S;
      PASS_S       :
        if( attack_detected )
          state_next = SUB_ATTACK_S;
        else
          if( envelope < noise_floor_i )
            state_next = SILENCE_S;
      SUB_ATTACK_S : if( attack_counter == '1 - 1'b1 ) state_next = PASS_S;
    endcase
  end


assign value = envelope - envelope_d1;

always_ff @( posedge clk_i )
  if( sample_tick_i )
    case( 1'b1 )
      ( state==SILENCE_S ) : attack_counter <= '0;
      ( state==ATTACK_S  ) : attack_counter <= attack_counter + 1'b1;
      ( state==PASS_S && state_next==SUB_ATTACK_S ) : attack_counter <= '1 - value;
    endcase



logic [DWIDTH-1:0] data_delayed;
logic              fifo_rdreq;
logic [11:0]       used_words;

showahead_sc_fifo #(
  .DWIDTH             ( DWIDTH                    ),
  .AWIDTH             ( 10                        )
) output_buffer (
  .clk_i              ( clk_i                     ),
  .srst_i             ( srst_i                    ),
  .data_i             ( data_i                    ),
  .wr_req_i           ( sample_tick_i             ),
  .empty_o            (                           ),
  .full_o             (                           ),
  .rd_req_i           ( fifo_rdreq                ),
  .data_o             ( data_delayed              ),
  .usedw_o            ( used_words                )
);

assign fifo_rdreq = sample_tick_i && ( used_words == 2**10-1 );


logic [8:0] attenuation;

always_comb
  if( state==ATTACK_S || state==SUB_ATTACK_S )
    attenuation = attack_counter >> (SWELL_DEPTH - 7);
  else
    attenuation = 9'd256;


logic [DWIDTH-1:0] data_attenuated;

attenuator attenuator(
  .data_signed_i ( data_delayed    ),
  .mult_i        ( attenuation     ),
  .data_o        ( data_attenuated )
);



//assign data_o = state==SILENCE_S ? '0 : data_attenuated;

assign data_o = enable_i ? (state==SILENCE_S ? '0 : data_attenuated) : data_i;


/*
attenuator gain_stage(
  .data_signed_i ( square_wave ),
  .mult_i        ( gain        ),
  .data_o        ( wet         )
);

attenuator gain_wet(
  .data_signed_i ( wet         ),
  .mult_i        ( wet_gain    ),
  .data_o        ( wet_gained  )
);

attenuator gain_dry(
  .data_signed_i ( data_i       ),
  .mult_i        ( dry_gain    ),
  .data_o        ( dry_gained  )
);

*/

endmodule
