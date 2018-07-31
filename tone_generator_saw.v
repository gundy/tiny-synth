/* =============================
 * Sawtooth tone generator
 * =============================
 *
 * Generates a sawtooth output waveform.
 *
 * Principle of operation:
 *
 * Take the upper OUTPUT_BITS from the accumulator.
 */
module tone_generator_saw #(
  parameter ACCUMULATOR_BITS = 24,
  parameter OUTPUT_BITS = 12)
(
  input [ACCUMULATOR_BITS-1:0] accumulator,
  output wire [OUTPUT_BITS-1:0] dout);

  assign dout = accumulator[ACCUMULATOR_BITS-1 -: OUTPUT_BITS];

endmodule
