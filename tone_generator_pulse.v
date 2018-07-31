/* =============================
 * Pulse (square) tone generator
 * =============================
 *
 * Generates a pulse-width modulated output according to accumulator value, at a duty
 * cycle determined by the pulse_width input.
 *
 * Principle of operation:
 *
 * If accumulator[MSB] <= pulse_width, then the output will be full-scale;
 * If accumulator[MSB] > pulse_width, then the output will be zero.
 *
 * Setting pulse_width to half of it's full-scale value will result in a
 * roughly square wave out.  Varying the value will result in pulse outputs with
 * varying duty cycles.
 */
module tone_generator_pulse #(
  parameter ACCUMULATOR_BITS = 24,
  parameter PULSEWIDTH_BITS = 12,
  parameter OUTPUT_BITS = 12)
(
  input [ACCUMULATOR_BITS-1:0] accumulator,
  input [PULSEWIDTH_BITS-1:0] pulse_width,
  output wire [OUTPUT_BITS-1:0] dout);

  localparam MAX_SCALE = (2**OUTPUT_BITS) - 1;

  // if accumulator value > pulse_width, output = MAX; else 0;
  assign dout = (accumulator[ACCUMULATOR_BITS-1 -: PULSEWIDTH_BITS] <= pulse_width) ? MAX_SCALE : 0;

endmodule
