/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Clifford Wolf <clifford@clifford.at>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

 /*
  * Some minor modifications have been made to Clifford's code to remove
  * some of the SoC integration complexities - I've also commented things
  * for my own understanding.
  *
  */
`ifndef __PICOSOC_SIMPLEUART__
`define __PICOSOC_SIMPLEUART__

 module simpleuart #(
   parameter CLOCK_FREQUENCY = 16000000,
   parameter BAUD_RATE = 115200
 ) (
 	input clk,
 	input resetn,   /* active low reset */

 	output ser_tx,  /* serial transmit out */
 	input  ser_rx,  /* serial receive in */

  output        recv_buf_valid,
  input         reg_dat_re,
  output [7:0]  reg_dat_do,

 	input         reg_dat_we,
 	input  [7:0]  reg_dat_di,
 	output        tx_busy);

 localparam cfg_divider = $rtoi(CLOCK_FREQUENCY / BAUD_RATE);

 /*
  * RECEIVE related registers
  */

  /* ===============================================================
   *  TABLE OF RECEIVE STATES
   * ===============================================================
   *
   * STATE | DESCRIPTION
   * ------+-------------------------
   *     0 | waiting for start bit
   *     1 | start bit detected, waiting for middle of start bit
   *     2 | waiting for middle of bit 0
   *     3 | waiting for middle of bit 1
   *     4 | waiting for middle of bit 2
   *     5 | waiting for middle of bit 3
   *     6 | waiting for middle of bit 4
   *     7 | waiting for middle of bit 5
   *     8 | waiting for middle of bit 6
   *     9 | waiting for middle of bit 7
   *    10 | waiting for middle of stop bit
   */
 	reg [3:0] recv_state;     /* recv_state is essentially a bit counter - indicating which bit the receiver is expecting */

 	reg [31:0] recv_divcnt;   /* up-counter, to count cycles for current bit */
 	reg [7:0] recv_pattern;   /* currently received pattern; clocked in from MSB end */
 	reg [7:0] recv_buf_data;  /* previously received byte */
 	reg recv_buf_valid;       /* flag to indicate that the buffered receive byte is valid, and can be clocked out with reg_dat_re */


  /* data out line is either data from the buffer (if the data is available and valid),
   *  or it's 0xff otherwise.
   */
 	assign reg_dat_do = recv_buf_valid ? recv_buf_data : ~0;
  assign tx_busy = reg_dat_we && (send_bitcnt || send_dummy);

  /* ===================================================================================================================== */

  /*
   * TRANSMIT related registers
   */
 	reg [9:0] send_pattern;   /* current pattern being clocked out on the serial line */
 	reg [3:0] send_bitcnt;    /* number of bits remaining to be sent */
 	reg [31:0] send_divcnt;   /* number of clock cycles counted for the current bit */
 	reg send_dummy;           /* flag to indicate that the next "slot" is empty */

  /* reg_dat_wait is asserted when an attempted write is not possible because
   *  the serial line is busy because it's either currently sending data
   *  (send_bitcnt is non-zero) or is about to send a dummy slot (send_dummy is 1).
   */
 	assign tx_busy = reg_dat_we && (send_bitcnt || send_dummy);

 	always @(posedge clk) begin
 		if (!resetn) begin
 			recv_state <= 0;
 			recv_divcnt <= 0;
 			recv_pattern <= 0;
 			recv_buf_data <= 0;
 			recv_buf_valid <= 0;
 		end else begin
 			recv_divcnt <= recv_divcnt + 1;

      /* if data has been clocked out, reset buf valid flag to 0 */
 			if (reg_dat_re)
 				recv_buf_valid <= 0;

 			case (recv_state)
 				0: begin
          /* if our serial input has been brought low, we're now
           * expecting the start bit */
 					if (!ser_rx)
 						recv_state <= 1;

 					recv_divcnt <= 0;
 				end
 				1: begin
          /* state 1 means we're waiting for the middle of the start bit. */
          if (ser_rx) begin
            // we had a false start bit; reset and try again
            recv_state <= 0;
          end else begin
   					if (2*recv_divcnt > cfg_divider) begin
              /* at this point we've aligned ourselves half-way
               * through the start-bit (notice the 2x multiplier above),
               * so we reset the counter to zero, and wait for the next
               * full-bit cycle(s) so we can sample the middle of the incoming bits.
               */
   						recv_state <= 2;
   						recv_divcnt <= 0;
   					end
          end
 				end
 				10: begin
 					if (recv_divcnt > cfg_divider) begin
            /* at this point we're in the middle of receiving the
             * stop bit, and rather than doing anything with it, we
             * use this as an opportunity to clock out the newly
             * received byte by setting the recv_buf_valid flag,
             * and then bounce back to state 0.  (note: stop-bit is
             * logic-level high, so we're ready to look for the next
             * high-low transition to signal the next bit).
             */
 						recv_buf_data <= recv_pattern;
 						recv_buf_valid <= 1;
 						recv_state <= 0;
 					end
 				end
 				default: begin
          /* states 2-9; clocking in bits 0-7. */
 					if (recv_divcnt > cfg_divider) begin
 						recv_pattern <= {ser_rx, recv_pattern[7:1]};
 						recv_state <= recv_state + 1;
 						recv_divcnt <= 0;
 					end
 				end
 			endcase
 		end
 	end

/* ====================================================================
 *  TRANSMIT LOGIC
 * ====================================================================
 */

  // clock out bit zero of send_pattern
 	assign ser_tx = send_pattern[0];

 	always @(posedge clk) begin
 		send_divcnt <= send_divcnt + 1;
 		if (!resetn) begin
      /* reset line low, so reset all signals */
 			send_pattern <= ~0;
 			send_bitcnt <= 0;
 			send_divcnt <= 0;
 			send_dummy <= 1;
 		end else begin
 			if (send_dummy && !send_bitcnt) begin
        /* send_dummy requested for next timing slot,
         * reset bit count to 15, set send pattern to all 1's,
         * clear send_dummy flag */
 				send_pattern <= ~0;
 				send_bitcnt <= 15;
 				send_divcnt <= 0;
 				send_dummy <= 0;
 			end else
 			if (reg_dat_we && !send_bitcnt) begin
        /* write-enable set, and we're not in the process of sending
         * any bits, so pull the send_pattern from our data-input port,
         * (surrounded by start and stop bits)
         */
 				send_pattern <= {1'b1, reg_dat_di, 1'b0};
 				send_bitcnt <= 10;
 				send_divcnt <= 0;
 			end else
 			if (send_divcnt > cfg_divider && send_bitcnt) begin
        /*
         * we're ready for the next bit, so rotate send_pattern one
         * bit to the right (and fill MSB with a 1).  Also
         * decrement the number of bits left to send, and
         * reset the counter.
         */
 				send_pattern <= {1'b1, send_pattern[9:1]};
 				send_bitcnt <= send_bitcnt - 1;
 				send_divcnt <= 0;
 			end
 		end
 	end
 endmodule

 `endif
