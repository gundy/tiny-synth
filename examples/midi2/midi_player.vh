`ifndef __TINY_SYNTH_MIDI_PLAYER__
`define __TINY_SYNTH_MIDI_PLAYER__

/* Using some slimmed-down versions of the voice code
   so that we can fit more voices in the budget */
`include "../../hdl/tone_generator.vh"
`include "envelope_generator_fixed_param.vh"
`include "voice_fixed_param.vh"

/* Clifford Wolf's simpleuart */
`include "simpleuart.vh"

/* .. and a wrapper for it that handles framing incoming messages into MIDI commands */
`include "midi_uart.vh"

module midi_player #(
  parameter SAMPLE_BITS = 12
) (
  input wire clk,
  input [3:0] waveform,
  input wire serial_rx,
  output wire serial_tx,
  output signed [SAMPLE_BITS-1:0] audio_data
);

  /* incoming midi data */
  reg [7:0] midi_uart_data;
  reg midi_byte_clk;
  reg midi_event_valid;
  wire [7:0] midi_command;
  wire [6:0] midi_parameter_1;
  wire [6:0] midi_parameter_2;
  wire midi_event_ack;

  midi_uart midi_uart(
    .clk(clk),
    .serial_rx(serial_rx), .serial_tx(serial_tx),
    .midi_event_valid(midi_event_valid),
    .midi_command(midi_command),
    .midi_parameter_1(midi_parameter_1),
    .midi_parameter_2(midi_parameter_2),
    .midi_event_ack(midi_event_ack)
  );

  /* CLOCK GENERATION; generate 1MHz clock for voice oscillators, and 44100Hz clock for sample output */
  wire ONE_MHZ_CLK;
  clock_divider #(.DIVISOR(16)) mhz_clk_divider(.cin(clk), .cout(ONE_MHZ_CLK));

  localparam SAMPLE_CLK_FREQ = 44100;

  // divide main clock down to 44100Hz for sample output (note this clock will have
  // a bit of jitter because 44.1kHz doesn't go evenly into 16MHz).
  wire SAMPLE_CLK;
  clock_divider #(
    .DIVISOR((16000000/SAMPLE_CLK_FREQ))
  ) sample_clk_divider(.cin(clk), .cout(SAMPLE_CLK));

  // number of voices to use
  // if you modify this, you'll also need to manually update the
  // mixing function below
  localparam NUM_VOICES = 8;

  // individual voices are mixed into here..
  // output is wider than a single voice, and gets "clamped" (or "saturated") into clamped_voice_out.
  reg signed [SAMPLE_BITS+$clog2(NUM_VOICES)-1:0] raw_combined_voice_out;
  wire signed [SAMPLE_BITS-1:0] clamped_voice_out;

  localparam signed MAX_SAMPLE_VALUE = (2**(SAMPLE_BITS-1))-1;
  localparam signed MIN_SAMPLE_VALUE = -(2**(SAMPLE_BITS-1));

  assign  clamped_voice_out = (raw_combined_voice_out > MAX_SAMPLE_VALUE)
                            ? MAX_SAMPLE_VALUE
                            : ((raw_combined_voice_out < MIN_SAMPLE_VALUE)
                              ? MIN_SAMPLE_VALUE
                              : raw_combined_voice_out[SAMPLE_BITS-1:0]);


  reg [NUM_VOICES-1:0] voice_gate;  /* MIDI gates */
  reg [NUM_VOICES-1:0] voice_idle;  /* is this voice idle / ready to accept a new note? */
  reg [15:0] voice_frequency[0:NUM_VOICES-1];  /* frequency of the voice */
  reg [6:0] voice_note[0:NUM_VOICES-1];        /* midi note that is playing on this voice */
  wire signed[SAMPLE_BITS-1:0] voice_samples[0:NUM_VOICES-1];  // samples for each voice

  // MIXER: this adds the output from the 8 voices together
  always @(posedge SAMPLE_CLK) begin
    raw_combined_voice_out <= (voice_samples[0]+voice_samples[1]+voice_samples[2]+voice_samples[3]
                                +voice_samples[4]+voice_samples[5]+voice_samples[6]+voice_samples[7])>>>2;
  end


  // pass voice output through a low-pass filter, and a flanger to spice it up a little
  wire signed[SAMPLE_BITS-1:0] filter_out;

 filter_ewma #(.DATA_BITS(SAMPLE_BITS)) filter(.clk(SAMPLE_CLK), .s_alpha(25), .din(clamped_voice_out), .dout(filter_out));
 flanger #(.SAMPLE_BITS(SAMPLE_BITS)) flanger(.sample_clk(SAMPLE_CLK), .din(filter_out), .dout(audio_data));

 localparam WAVE_NOISE=4;
 localparam WAVE_PULSE=3;
 localparam WAVE_SAW=2;
 localparam WAVE_TRIANGLE=1;

  localparam WAVEFORM=WAVE_SAW;
  localparam [7:0] SUSTAIN_VOLUME=128;

  localparam ACCUMULATOR_BITS = 26;
  localparam  ACCUMULATOR_SIZE = 2**ACCUMULATOR_BITS;
  localparam  ACCUMULATOR_MAX  = ACCUMULATOR_SIZE-1;


  `define CALCULATE_PHASE_INCREMENT(n) $rtoi(ACCUMULATOR_SIZE / ($itor(n) * SAMPLE_CLK_FREQ))

  localparam ATTACK_INC =  `CALCULATE_PHASE_INCREMENT(0.038);
  localparam DECAY_INC =  `CALCULATE_PHASE_INCREMENT(0.038);
  localparam RELEASE_INC =  `CALCULATE_PHASE_INCREMENT(0.8);


  generate
    genvar i;
    /* generate some voices and wire them to the per-MIDI-note gates */
    for (i=0; i<NUM_VOICES; i=i+1)
    begin : voices
      voice_fixed_param #(
        .OUTPUT_BITS(SAMPLE_BITS),
        .ATTACK_INC(ATTACK_INC), .DECAY_INC(DECAY_INC), .SUSTAIN_VOLUME(SUSTAIN_VOLUME), .RELEASE_INC(RELEASE_INC)
      ) voice (
        .main_clk(ONE_MHZ_CLK), .sample_clk(SAMPLE_CLK), .tone_freq(voice_frequency[i]), .rst(1'b0),
        .en_ringmod(1'b0), .ringmod_source(1'b0),
        .en_sync(1'b0), .sync_source(1'b0),
        .pulse_width(12'd600),
        .dout(voice_samples[i]),
        .is_idle(voice_idle[i]),
        .waveform(waveform),
        .gate(voice_gate[i])
      );
    end
  endgenerate

  `include "midi_note_to_tone_freq.vh"


  integer voice_idx;
  wire [15:0] tone_freq;
  assign tone_freq = midi_note_to_tone_freq(midi_parameter_1);

  /* handle read and acknowledgement of UART data, and clocking it in to the MIDI framer */
  always @(posedge clk) begin : midi_note_processor
    if (midi_event_valid && !midi_event_ack) begin
      // acknowledge the incoming MIDI event (this will automatically clear the _event_valid flag)
      midi_event_ack <= 1'b1;

      case (midi_command[7:4])
        // note on ; find an idle voice and assign this note to it (and gate it on)
        // the long chain below is because yosys doesn't support the "disable" statement.
        4'h9: begin
                if (!(
                    voice_note[0] == midi_parameter_1
                    || voice_note[1] == midi_parameter_1
                    || voice_note[2] == midi_parameter_1
                    || voice_note[3] == midi_parameter_1
                    || voice_note[4] == midi_parameter_1
                    || voice_note[5] == midi_parameter_1
                    || voice_note[6] == midi_parameter_1
                    || voice_note[7] == midi_parameter_1
                  )) begin
                    if (voice_idle[0]) begin
                      voice_note[0] <= midi_parameter_1;
                      voice_frequency[0] <= tone_freq;
                      voice_gate[0] <= 1'b1;
                    end else if (voice_idle[1]) begin
                      voice_note[1] <= midi_parameter_1;
                      voice_frequency[1] <= tone_freq;
                      voice_gate[1] <= 1'b1;
                    end else if (voice_idle[2]) begin
                      voice_note[2] <= midi_parameter_1;
                      voice_frequency[2] <= tone_freq;
                      voice_gate[2] <= 1'b1;
                    end else if (voice_idle[2]) begin
                      voice_note[2] <= midi_parameter_1;
                      voice_frequency[2] <= tone_freq;
                      voice_gate[2] <= 1'b1;
                    end else if (voice_idle[3]) begin
                      voice_note[3] <= midi_parameter_1;
                      voice_frequency[3] <= tone_freq;
                      voice_gate[3] <= 1'b1;
                    end else if (voice_idle[4]) begin
                      voice_note[4] <= midi_parameter_1;
                      voice_frequency[4] <= tone_freq;
                      voice_gate[4] <= 1'b1;
                    end else if (voice_idle[5]) begin
                      voice_note[5] <= midi_parameter_1;
                      voice_frequency[5] <= tone_freq;
                      voice_gate[5] <= 1'b1;
                    end else if (voice_idle[6]) begin
                      voice_note[6] <= midi_parameter_1;
                      voice_frequency[6] <= tone_freq;
                      voice_gate[6] <= 1'b1;
                    end else if (voice_idle[7]) begin
                      voice_note[7] <= midi_parameter_1;
                      voice_frequency[7] <= tone_freq;
                      voice_gate[7] <= 1'b1;
                    end
                  end
              end
        // note off ; find the voice playing this note, and gate it off.
        4'h8: begin
                for (voice_idx = 0; voice_idx < NUM_VOICES; voice_idx = voice_idx + 1) begin
                  if (voice_note[voice_idx] == midi_parameter_1) begin
                    voice_note[voice_idx] <= 0;
                    voice_gate[voice_idx] <= 1'b0;
                  end
                end
              end
      endcase
    end else begin
      // no event to acknowledge, so clear ack flag
      midi_event_ack <= 1'b0;
    end

  end

endmodule

`endif
