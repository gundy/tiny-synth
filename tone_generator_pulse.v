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
  assign dout = (accumulator[ACCUMULATOR_BITS-1 -: PULSEWIDTH_BITS] > pulse_width) ? MAX_SCALE : 0;

endmodule
