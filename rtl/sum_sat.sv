module sum_sat #( parameter DW = 16 ) ( input [DW-1:0] x, y, output logic [DW-1:0] z );
logic [DW:0] sum;
assign sum = {x[DW-1],x} + {y[DW-1],y};
always_comb
  case( {sum[DW], sum[DW-1] } )
    2'b01   : z = {1'b0, {(DW-2){1'b1}}};
    2'b10   : z = {1'b1, {(DW-2){1'b0}}};
    default : z = {sum[DW], sum[DW-2:0]};
  endcase
endmodule
