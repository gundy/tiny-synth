`ifndef __TINY_SYNTH_VOICE_FIXED_PARAM__
`define __TINY_SYNTH_VOICE_FIXED_PARAM__

`include "../../hdl/tone_generator.vh"
`include "envelope_generator_fixed_param.vh"
`include "../../hdl/amplitude_modulator.vh"

module voice_fixed_param #(
  parameter OUTPUT_BITS = 12,
  parameter FREQ_BITS = 16,
  parameter PULSEWIDTH_BITS = 12,
  parameter ACCUMULATOR_BITS = 24,
  parameter SAMPLE_CLK_FREQ = 44100,
  parameter ATTACK_INC = 1000,
  parameter DECAY_INC = 1000,
  parameter [7:0] SUSTAIN_VOLUME = 128,
  parameter RELEASE_INC = 1000
)(
  input [FREQ_BITS-1:0] tone_freq,
  input [PULSEWIDTH_BITS-1:0] pulse_width,
  input main_clk,
  input sample_clk,
  input rst,
  input [3:0] waveform,
  output wire signed [OUTPUT_BITS-1:0] dout,
  output wire accumulator_msb,   /* used to feed ringmod on another voice */
  output wire accumulator_overflow,  /* set when accumulator = 0; used to sync with another oscillator */
  output wire is_idle,
  input en_ringmod,
  input wire ringmod_source,
  input en_sync,
  input wire sync_source,

  // envelope generator params
  input wire gate
);

  wire signed [OUTPUT_BITS-1:0] tone_generator_data;
  wire[7:0] envelope_amplitude;

  tone_generator #(
    .FREQ_BITS(FREQ_BITS),
    .PULSEWIDTH_BITS(PULSEWIDTH_BITS),
    .OUTPUT_BITS(OUTPUT_BITS),
    .ACCUMULATOR_BITS(ACCUMULATOR_BITS),
  ) tone_generator (
      .tone_freq(tone_freq),
      .pulse_width(pulse_width),
      .main_clk(main_clk),
      .sample_clk(sample_clk),
      .rst(rst),
      .dout(tone_generator_data),
      .accumulator_msb(accumulator_msb),
      .accumulator_overflow(accumulator_overflow),
      .en_sync(en_sync),
      .sync_source(sync_source),
      .en_ringmod(en_ringmod),
      .ringmod_source(ringmod_source),
      .en_noise(waveform[0]),
      .en_pulse(waveform[1]),
      .en_triangle(waveform[2]),
      .en_saw(waveform[3])
    );

  envelope_generator_fixed_param #(
    .SAMPLE_CLK_FREQ(SAMPLE_CLK_FREQ),
    .ATTACK_INC(ATTACK_INC),
    .DECAY_INC(DECAY_INC),
    .SUSTAIN_VOLUME(SUSTAIN_VOLUME),
    .RELEASE_INC(RELEASE_INC)
  ) envelope(
    .clk(sample_clk),
    .rst(rst),
    .gate(gate),
    .is_idle(is_idle),
    .amplitude(envelope_amplitude)
  );

  amplitude_modulator #(.DATA_BITS(OUTPUT_BITS)) modulator(
    .clk(sample_clk),
    .din(tone_generator_data),
    .amplitude(envelope_amplitude),
    .dout(dout)
  );

endmodule

`endif
