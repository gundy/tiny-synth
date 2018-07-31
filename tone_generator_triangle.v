module tone_generator_triangle #(
  parameter ACCUMULATOR_BITS = 24,
  parameter OUTPUT_BITS = 12)
(
  input [ACCUMULATOR_BITS-1:0] accumulator,
  output wire [OUTPUT_BITS-1:0] dout,
  input en_ringmod,
  input ringmod_source);

  wire invert_wave;

  // invert the waveform (ie. start counting down instead of up)
  // if either ringmod is enabled and high,
  // or MSB of accumulator is set.
  assign invert_wave = (en_ringmod && ringmod_source)
                    || (!en_ringmod && accumulator[ACCUMULATOR_BITS-1]);

  assign dout = invert_wave ? ~accumulator[ACCUMULATOR_BITS-2 -: OUTPUT_BITS]
                            : accumulator[ACCUMULATOR_BITS-2 -: OUTPUT_BITS];

endmodule
