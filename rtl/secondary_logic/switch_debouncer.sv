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
 * -- Dmitry Nekrasov <bluebag@yandex.ru>   Mon, 08 Apr 2024 08:50:31 +0300
 */

module switch_debouncer #(
  parameter NUM            = 2,
  parameter DEBOUNCE_DEPTH = 13
) (
  input                  clk_i,
  input                  srst_i,
  input        [NUM-1:0] data_i,
  output logic [NUM-1:0] data_o
);

typedef enum logic [1:0] {
  UNPRESSED_S,
  PRESS_S,
  PRESSED_S,
  UNPRESS_S
} state_t;

genvar i;
generate
  for( i = 0; i < NUM; i++ )
    begin : gen_debounce
      logic [DEBOUNCE_DEPTH-1:0] cnt;
      state_t state;

      always_ff @( posedge clk_i )
        if( srst_i )
          state <= UNPRESSED_S;
        else
          case ( state )
            UNPRESSED_S : if( data_i[i]  ) state <= PRESS_S;
            PRESS_S     : if( cnt=='1    ) state <= PRESSED_S;
            PRESSED_S   : if( !data_i[i] ) state <= UNPRESS_S;
            UNPRESS_S   : if( cnt=='1    ) state <= UNPRESSED_S;
          endcase

      always_ff @( posedge clk_i )
        cnt <= ( state==PRESS_S || state==UNPRESS_S ) ? cnt + 1'b1 : '0;

      assign data_o[i] = ( state==PRESS_S || state==PRESSED_S );
    end // gen_debounce
endgenerate
endmodule
