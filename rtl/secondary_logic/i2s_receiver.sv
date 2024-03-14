module i2s_receiver #(
  parameter DATA_WIDTH = 16,
  parameter I2S_FORMAT = "True"
) (
  i2s_if                        i2s,
  input                         clk_i,
  input                         srst_i,
  output logic [DATA_WIDTH-1:0] data_o,
  output logic                  data_val_o
);

enum logic { RIGHT_S, LEFT_S } state, state_next;

logic [1:0]          sclk_d;
logic [2:0]          lrclk_d;
logic                sclk_posedge;
logic                i2s_clk_posedge;
logic                word_end;
logic [31:0]         input_reg; // 32 because ADC sends 32-bit words
logic [$clog2(32):0] posedge_cnt;

always_ff @( posedge clk_i )
  begin
    sclk_d  <= {sclk_d[0],    i2s.bclk  };
    lrclk_d <= {lrclk_d[1:0], i2s.lrclk };
  end

always_ff @( posedge clk_i )
  state <= srst_i ? LEFT_S : state_next;

always_comb
  begin
    state_next = state;
    case( state )
      LEFT_S  : if(  lrclk_d[2:1] == 2'b01 ) state_next = RIGHT_S;
      RIGHT_S : if(  lrclk_d[2:1] == 2'b10 ) state_next = LEFT_S;
    endcase
  end

assign sclk_posedge    = ( sclk_d == 2'b01 );
assign i2s_clk_posedge = sclk_posedge  && state==LEFT_S;
assign word_end        = state==LEFT_S && state_next==RIGHT_S;

always_ff @( posedge clk_i )
  if( srst_i || word_end )
    posedge_cnt <= '0;
  else
    if( i2s_clk_posedge )
      posedge_cnt <= posedge_cnt + 1'b1;

always_ff @( posedge clk_i )
  for( int i = 0; i < 32; i++ )
    if( i2s_clk_posedge && posedge_cnt==i )
      input_reg[31-i] <= i2s.data_from_adc;

always_ff @( posedge clk_i )
  if( word_end )
    data_o <= I2S_FORMAT=="True" ? input_reg[31:(32-DATA_WIDTH)] << 1 :
                                   input_reg[31:(32-DATA_WIDTH)];

always_ff @( posedge clk_i )
  data_val_o <= word_end;

endmodule
