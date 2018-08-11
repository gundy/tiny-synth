`ifndef __TINY_SYNTH_MIDI_FRAMER__
`define __TINY_SYNTH_MIDI_FRAMER__

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
 */

module midi_framer(
  input [7:0] din,                  /* input raw byte data from MIDI bus */
  input din_clk,                    /* input clock (pos edge) */

  output [7:0] midi_command,        /* output: MIDI command byte */
  output [7:0] midi_parameter_1,    /* output: MIDI parameter #1 */
  output [7:0] midi_parameter_2,    /* output: MIDI parameter #2 */
  output wire midi_event_valid,     /* output: MIDI command and parameters contain valid data */

  input midi_data_ack               /* bring this high to acnowledge receipt of a midi_event_valid notification */
);

  /* command and parameters *currently* being clocked in */
  reg[7:0] in_flight_cmd;
  reg[15:0] in_flight_param;
  reg[2:0] in_flight_recvd_param_count;
  reg[2:0] in_flight_expected_param_count;

  /* previously clocked in command & parameters - ready for output */
  reg[7:0] buf_cmd;
  reg[15:0] buf_param;
  reg buf_midi_event_valid;

  assign midi_parameter_1 = buf_param[15:8];
  assign midi_parameter_2 = buf_param[7:0];
  assign midi_command = buf_cmd;
  assign midi_event_valid = buf_midi_event_valid;

  initial begin
    buf_midi_event_valid <= 1'b0;
    buf_cmd <= 8'h00;
    buf_param <= 16'h0000;

    in_flight_cmd <= 8'h00;
    in_flight_param <= 16'h0000;
    in_flight_recvd_param_count <= 2'h0;
    in_flight_expected_param_count <= 2'h0;
  end

  function [2:0] expected_midi_parameter_count(
      input [3:0] midi_command
    );
    case (midi_command)
      4'hc: expected_midi_parameter_count = 1;     /* patch change */
      4'hd: expected_midi_parameter_count = 1;     /* channel pressure */
      default: expected_midi_parameter_count = 2;
    endcase
  endfunction

  always @(posedge din_clk)
  begin
    if (midi_data_ack) begin
      buf_cmd <= 0;
      buf_param <= 0;
      buf_midi_event_valid <= 0;
    end

    if ((in_flight_cmd >= 8'h80 && in_flight_cmd < 8'hf0)
         && (in_flight_recvd_param_count == in_flight_expected_param_count)
      ) begin
      buf_cmd <= in_flight_cmd;
      buf_param <= in_flight_param;
      buf_midi_event_valid <= 1'b1;
    end

    if (din[7] == 1'b1) begin  /* MSB is set, so din is a new command */
      in_flight_cmd <= din;
      in_flight_param <= 0;
      in_flight_expected_param_count <= expected_midi_parameter_count(din[7:4]);
      in_flight_recvd_param_count <= 0;
    end else begin
      /* we've received a byte without the MSB set - ie. a parameter */
      if (in_flight_expected_param_count == 1) begin
        in_flight_param <= { 8'd0, din };
      end else begin
        in_flight_param <= { din, in_flight_param[15:8] };
      end
      in_flight_recvd_param_count <= in_flight_recvd_param_count + 1;
    end

  end

endmodule

`endif
