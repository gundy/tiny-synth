module voice #(
  parameter OUTPUT_BITS = 12,
  parameter FREQ_BITS = 16,
  parameter PULSEWIDTH_BITS = 12
)(
  input [FREQ_BITS-1:0] tone_freq,
  input [3:0] waveform_enable,
  input [PULSEWIDTH_BITS-1:0] pulse_width,
  input clk,
  input rst,
  output wire [OUTPUT_BITS-1:0] dout,
  output wire accumulator_msb,  /* used to feed ringmod/sync on another voice */
  input ringmod_enable,
  input wire ringmod_source,

  // envelope generator params
  input wire gate,
  input [3:0] attack,
  input [3:0] decay,
  input [3:0] sustain,
  input [3:0] rel
);

  wire [11:0] tone_generator_data;
  wire[7:0] envelope_amplitude;

  tone_generator tone_generator(
      .tone_freq(tone_freq),
      .waveform_enable(waveform_enable),
      .pulse_width(pulse_width),
      .clk(clk),
      .rst(rst),
      .dout(tone_generator_data),
      .accumulator_msb(accumulator_msb),
      .ringmod_enable(ringmod_enable),
      .ringmod_source(ringmod_source)
    );

  envelope_generator envelope(
    .clk(clk),
    .rst(rst),
    .gate(gate),
    .a(attack),
    .d(decay),
    .s(sustain),
    .r(rel),
    .amplitude(envelope_amplitude)
  );

  amplitude_modulator modulator(
    .clk(clk),
    .din(tone_generator_data),
    .amplitude(envelope_amplitude),
    .dout(dout)
  );

endmodule
