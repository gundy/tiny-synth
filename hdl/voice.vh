`ifndef __TINY_SYNTH_VOICE__
`define __TINY_SYNTH_VOICE__

`include "tone_generator.vh"
`include "envelope_generator.vh"
`include "amplitude_modulator.vh"

module voice #(
  parameter OUTPUT_BITS = 12,
  parameter FREQ_BITS = 16,
  parameter PULSEWIDTH_BITS = 12,
  parameter ACCUMULATOR_BITS = 24,
  parameter SAMPLE_CLK_FREQ = 44100
)(
  input [FREQ_BITS-1:0] tone_freq,
  input [3:0] waveform_enable,
  input [PULSEWIDTH_BITS-1:0] pulse_width,
  input main_clk,
  input sample_clk,
  input rst,
  input test,
  output wire signed [OUTPUT_BITS-1:0] dout,
  output wire accumulator_msb,   /* used to feed ringmod on another voice */
  output wire sync_trigger_out,  /* used to sync with another oscillator */
  input en_ringmod,
  input wire ringmod_source,
  input en_sync,
  input wire sync_source,

  // envelope generator params
  input wire gate,
  input [3:0] attack,
  input [3:0] decay,
  input [3:0] sustain,
  input [3:0] rel
);

  wire signed [OUTPUT_BITS-1:0] tone_generator_data;
  wire[7:0] envelope_amplitude;

  tone_generator #(
    .FREQ_BITS(FREQ_BITS),
    .PULSEWIDTH_BITS(PULSEWIDTH_BITS),
    .OUTPUT_BITS(OUTPUT_BITS),
    .ACCUMULATOR_BITS(ACCUMULATOR_BITS)
  ) tone_generator (
      .tone_freq(tone_freq),
      .en_noise(waveform_enable[3]),
      .en_pulse(waveform_enable[2]),
      .en_saw(waveform_enable[1]),
      .en_triangle(waveform_enable[0]),
      .pulse_width(pulse_width),
      .main_clk(main_clk),
      .sample_clk(sample_clk),
      .rst(rst),
      .test(test),
      .dout(tone_generator_data),
      .accumulator_msb(accumulator_msb),
      .sync_trigger_out(sync_trigger_out),
      .en_sync(en_sync),
      .sync_source(sync_source),
      .en_ringmod(en_ringmod),
      .ringmod_source(ringmod_source)
    );

  envelope_generator #(
    .SAMPLE_CLK_FREQ(SAMPLE_CLK_FREQ)
  )
    envelope(
    .clk(sample_clk),
    .rst(rst),
    .gate(gate),
    .a(attack),
    .d(decay),
    .s(sustain),
    .r(rel),
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
