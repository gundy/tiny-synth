`ifndef __TINY_SYNTH_MIDI_PLAYER__
`define __TINY_SYNTH_MIDI_PLAYER__

`include "simpleuart.vh"
`include "midi_framer.vh"
`include "midi_note_lookup.vh"

/*
 * This is a _very_ simple MIDI player.
 *
 * It only has single-note polyphony
 */

module midi_player #(
  parameter SAMPLE_BITS = 12
) (
  input wire clk,
  input wire serial_rx,
  output wire serial_tx,
  output signed [SAMPLE_BITS-1:0] audio_data
);

  reg [7:0] uart_rx_data;
  reg uart_read_ack;
  wire uart_recv_data_valid;

  reg uart_tx_wait;  /* not used */

  /* incoming midi data */
  reg [7:0] midi_uart_data;
  reg midi_byte_clk;
  reg midi_event_valid;
  reg [7:0] midi_command;
  reg [7:0] midi_parameter_1;
  reg [7:0] midi_parameter_2;

  wire midi_data_ack;

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
    .reg_dat_wait(uart_tx_wait)
  );

  midi_framer framer(
    .din(midi_uart_data), .din_clk(midi_byte_clk),  /* clock data into framer based on uart data valid signal */
    .midi_event_valid(midi_event_valid),
    .midi_command(midi_command),
    .midi_parameter_1(midi_parameter_1),
    .midi_parameter_2(midi_parameter_2),
    .midi_data_ack(midi_data_ack)
  );

  /* CLOCK GENERATION; generate 1MHz clock for voice oscillators, and 44100Hz clock for sample output */
  wire ONE_MHZ_CLK;
  clock_divider #(.DIVISOR(16)) mhz_clk_divider(.cin(clk), .cout(ONE_MHZ_CLK));

  // divide main clock down to 44100Hz for sample output (note this clock will have
  // a bit of jitter because 44.1kHz doesn't go evenly into 16MHz).
  wire SAMPLE_CLK;
  clock_divider #(
    .DIVISOR((16000000/44100))
  ) sample_clk_divider(.cin(clk), .cout(SAMPLE_CLK));

  reg signed [SAMPLE_BITS-1:0] raw_voice_out[0:60];
  reg instrument_gate[0:127];  /* MIDI gates */

  wire signed [11:0] raw_combined_voice_out;

  assign raw_combined_voice_out = raw_voice_out[0]+raw_voice_out[1]+raw_voice_out[2]+raw_voice_out[3]+raw_voice_out[4]+raw_voice_out[5]+raw_voice_out[6]+raw_voice_out[7]+raw_voice_out[8]+raw_voice_out[9]
              + raw_voice_out[10]+raw_voice_out[11]+raw_voice_out[12]+raw_voice_out[13]+raw_voice_out[14]+raw_voice_out[15]+raw_voice_out[16]+raw_voice_out[17]+raw_voice_out[18]+raw_voice_out[19]
              + raw_voice_out[20]+raw_voice_out[21]+raw_voice_out[22]+raw_voice_out[23]+raw_voice_out[24]+raw_voice_out[25]+raw_voice_out[26]+raw_voice_out[27]+raw_voice_out[28]+raw_voice_out[29]
              + raw_voice_out[30]+raw_voice_out[31]+raw_voice_out[32]+raw_voice_out[33]+raw_voice_out[34]+raw_voice_out[35]+raw_voice_out[36]+raw_voice_out[37]+raw_voice_out[38]+raw_voice_out[39]
              + raw_voice_out[40]+raw_voice_out[41]+raw_voice_out[42]+raw_voice_out[43]+raw_voice_out[44]+raw_voice_out[45]+raw_voice_out[46]+raw_voice_out[47]+raw_voice_out[48]+raw_voice_out[49]
              + raw_voice_out[50]+raw_voice_out[51]+raw_voice_out[52]+raw_voice_out[53]+raw_voice_out[54]+raw_voice_out[55]+raw_voice_out[56]+raw_voice_out[57]+raw_voice_out[58]+raw_voice_out[59];

  // pass voice output through a low-pass filter, and a flanger to spice it up a little
  wire signed[SAMPLE_BITS-1:0] filter_out;
  filter_ewma #(.DATA_BITS(SAMPLE_BITS)) filter(.clk(SAMPLE_CLK), .s_alpha(10), .din(raw_combined_voice_out), .dout(filter_out));
  flanger #(.SAMPLE_BITS(SAMPLE_BITS)) flanger(.sample_clk(SAMPLE_CLK), .din(filter_out), .dout(audio_data));

  genvar i;
  generate
      /* generate some voices and wire them to the per-MIDI-note gates */
      for (i=24; i<=72; i=i+1) begin : voices
        voice #(.OUTPUT_BITS(SAMPLE_BITS)) instrument_voice(
          .main_clk(ONE_MHZ_CLK), .sample_clk(SAMPLE_CLK), .tone_freq($rtoi((2 ** ((i-84)/12)) * 17557.0)), .rst(1'b0),
          .en_ringmod(1'b0), .ringmod_source(1'b0),
          .en_sync(1'b0), .sync_source(1'b0),
          .waveform_enable(4'b0100), .pulse_width(12'd600),
          .attack(4'b0100), .decay(4'b1100), .sustain(4'b0000), .rel(4'b1100),
          .dout(raw_voice_out[i-24]),
          .gate(instrument_gate[i])
        );
      end
  endgenerate

  /* handle read and acknowledgement of UART data, and clocking it in to the MIDI framer */
  always @(posedge clk)
  begin
    if (uart_recv_data_valid)
    begin
      uart_read_ack <= 1'b1;
      midi_uart_data <= uart_rx_data;
      midi_byte_clk <= 1'b1;
    end
    else
    begin
      uart_read_ack <= 1'b0;
      midi_byte_clk <= 1'b0;
    end
  end

  /* handle output from MIDI framer */
  always @(posedge clk)
  begin
    if (midi_event_valid)
    begin
      case (midi_command[7:4])
        /***************************\
        *  note off                 *
        \***************************/
        4'h8:
        begin
          instrument_gate[midi_parameter_1[6:0]] <= 1'b0;
        end
        /***************************\
        *  note on                  *
        \***************************/
        4'h9:
        begin
          instrument_gate[midi_parameter_1[6:0]] <= 1'b1;
        end
      endcase
      midi_data_ack <= 1;
    end
    else
    begin
      midi_data_ack <= 0;
    end
  end

endmodule

`endif
