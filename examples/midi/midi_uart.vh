`ifndef __TINY_SYNTH_MIDI_UART__
`define __TINY_SYNTH_MIDI_UART__

/*
 * A module which converts raw incoming MIDI byte data into events
 * with their parameters, ready for further processing.
 *
 *                     ______________
 *    byte stream     |             |  24-bit midi events
 *  ----------------> | MIDI framer | --------------------->
 *                    |_____________|
 *
 *  MIDI commands have quite a simple structure.
 *
 * The first (command) byte can be recognised by the fact that has the MSB set.
 *
 * Valid commands for our purposes range from 0x80 to 0xEF.
 *
 * Command  Meaning         # parameters 	param 1 	    param 2
 * 0x80 	  Note-off                   2  key           velocity
 * 0x90 	  Note-on                    2  key           velocity
 * 0xA0 	  Aftertouch                 2  key           touch
 * 0xB0 	  Continuous controller      2  controller #  controller value
 * 0xC0 	  Patch change               1  instrument #
 * 0xD0 	  Channel Pressure           1  pressure
 * 0xE0 	  Pitch bend                 2  lsb (7 bits) 	msb (7 bits)
 * 0xF0 	  (non-musical commands)
 *
 * NOTE: MIDI allows a single "command" byte to be followed by multiple
 *       sets of parameters - the command byte is remembered.
 */

module midi_uart(
  input [7:0] din,                  /* input raw byte data from MIDI bus */
  input din_clk,                    /* input clock (pos edge) */
  input clk,
  input serial_rx,
  output serial_tx,

  input midi_event_ack,
  output [7:0] midi_command,        /* output: MIDI command byte */
  output [6:0] midi_parameter_1,    /* output: MIDI parameter #1 */
  output [6:0] midi_parameter_2,    /* output: MIDI parameter #2 */
  output reg midi_event_valid     /* output: MIDI command and parameters contain valid data */
);

  reg [7:0] uart_rx_data;
  reg uart_read_ack;
  reg uart_recv_data_valid;

  reg uart_tx_busy;  /* not used */


  reg [3:0] state;  /* number of MIDI bytes received (including command) */
  reg [21:0] in_flight_midi_message;
  reg [2:0] in_flight_expected_param_count;

  simpleuart #(.CLOCK_FREQUENCY(16000000), .BAUD_RATE(31250)) uart(
    .clk(clk), .resetn(1'b1),
    .ser_rx(serial_rx),
    .reg_dat_re(uart_read_ack),
    .reg_dat_do(uart_rx_data),
    .recv_buf_valid(uart_recv_data_valid),

    /* we never write to the UART */
    .ser_tx(serial_tx),
    .reg_dat_we(1'b0),
    .reg_dat_di(8'd0),
    .tx_busy(uart_tx_busy)
  );

  initial begin
    midi_event_valid <= 1'b0;
    midi_command <= 8'h00;
    midi_parameter_1 <= 7'h00;
    midi_parameter_2 <= 7'h00;

    in_flight_expected_param_count <= 2'h0;
  end

  function [2:0] expected_midi_parameter_count(
      input [3:0] command
    );
    begin
      case (command)
        4'hc: expected_midi_parameter_count = 3'd1;     /* patch change */
        4'hd: expected_midi_parameter_count = 3'd1;     /* channel pressure */
        default: expected_midi_parameter_count = 3'd2;
      endcase
    end
  endfunction

  always @(posedge clk)
  begin
    if (midi_event_ack) begin
      midi_event_valid <= 0;
    end

    if (uart_recv_data_valid && !uart_read_ack) begin
      // we've just read a new byte from the UART
      if (uart_rx_data[7:4] == 4'hf) begin
        state <= 4'hf;
      end else if (uart_rx_data[7] === 1'b1) begin
        // the MSB was set, so this signifies a new MIDI "command"
        state <= 1;
        in_flight_expected_param_count <= expected_midi_parameter_count(uart_rx_data[7:4]);
        in_flight_midi_message <= { uart_rx_data, 14'b0 };
      end else begin
        // MSB was not set, so this is a parameter byte
        case (state)
          1: begin  // waiting for parameter #1 to arrive
              if (in_flight_expected_param_count == 1)
              begin
                // if we only wanted one parameter, then we've got it, so
                // clock this out as a valid MIDI event
                midi_command <= in_flight_midi_message[21:14];
                midi_parameter_1 <= uart_rx_data;
                midi_parameter_2 <= 7'b0;
                midi_event_valid <= 1'b1;
                state <= 1;
              end else begin
                // our MIDI command expected more than one parameter,
                // so we need to wait for the next to arrive.
                in_flight_midi_message <= { in_flight_midi_message[21:14], uart_rx_data[6:0], 7'b0 };
                state <= state + 1;
              end
            end
          2: begin // waiting for parameter #2 to arrive
              if (in_flight_expected_param_count == 2)
              begin
                // we were expecting two parameters, we've got them,
                // so clock them out as a valid MIDI event
                midi_command <= in_flight_midi_message[21:14];
                midi_parameter_1 <= in_flight_midi_message[13:7];
                midi_parameter_2 <= uart_rx_data[6:0];
                midi_event_valid <= 1'b1;
              end
              // we don't support commands with more than 2 parameters,
              // so now we transition to a "null" state, until the next
              // command arrives.
              state <= 1;
            end
          default: begin
            state <= 4'hf;
          end
        endcase
      end

      uart_read_ack <= 1'b1;
    end else begin
      uart_read_ack <= 1'b0;
    end

  end

endmodule

`endif
