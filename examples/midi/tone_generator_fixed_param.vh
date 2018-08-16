`ifndef __TINY_SYNTH_TONE_GENERATOR_AGGREGATE_FIXED_PARAM__
`define __TINY_SYNTH_TONE_GENERATOR_AGGREGATE_FIXED_PARAM__

`include "../../hdl/tone_generator_saw.vh"
`include "../../hdl/tone_generator_pulse.vh"
`include "../../hdl/tone_generator_triangle.vh"
`include "../../hdl/tone_generator_noise.vh"

/* =========================================================
 * Phase-accumulator tone-generator (with fixed parameters)
 * =========================================================
 *
 * This is a version of tone_generator with fixed (immutable)
 * parameters - this is so it can synthesise down to a simpler
 * implementation.
 *
 * This module aggregates the other tone generators together.
 *
 * It houses the accumulator and the logic for incrementing it
 * at a given frequency.
 *
 * It allows individual tone generators to be selected and logically
 * "ANDed" into the output stream.
 *
 * It also has provision for syncing oscillators together based on
 * when they overflow, and proving the accumulator MSB for ring
 * modulation purposes.
 */
module tone_generator_fixed_param #(
  parameter FREQ_BITS = 16,
  parameter PULSEWIDTH_BITS = 12,
  parameter OUTPUT_BITS = 12,
  parameter ACCUMULATOR_BITS = 24,
  parameter WAVEFORM = 1
) (
  input [FREQ_BITS-1:0] tone_freq,
  input [PULSEWIDTH_BITS-1:0] pulse_width,
  input main_clk,
  input sample_clk,
  input rst,
  output reg signed [OUTPUT_BITS-1:0] dout,
  output wire accumulator_msb,
  output wire accumulator_overflow,

  input wire en_ringmod,
  input wire ringmod_source,

  input wire en_sync,
  input wire sync_source
);

  reg [ACCUMULATOR_BITS:0] accumulator;

  wire [OUTPUT_BITS-1:0] wave_out;

  generate
    if (WAVEFORM == 1)
      tone_generator_triangle #(
          .ACCUMULATOR_BITS(ACCUMULATOR_BITS),
          .OUTPUT_BITS(OUTPUT_BITS)
      ) triangle_generator (
          .accumulator(accumulator[ACCUMULATOR_BITS-1:0]),
          .dout(wave_out),
          .en_ringmod(en_ringmod),
          .ringmod_source(ringmod_source)
        );
    if (WAVEFORM == 2)
      tone_generator_saw  #(
          .ACCUMULATOR_BITS(ACCUMULATOR_BITS),
          .OUTPUT_BITS(OUTPUT_BITS)
        ) saw(
          .accumulator(accumulator[ACCUMULATOR_BITS-1:0]),
          .dout(wave_out)
        );
    if (WAVEFORM == 3)
      tone_generator_pulse  #(
          .ACCUMULATOR_BITS(ACCUMULATOR_BITS),
          .OUTPUT_BITS(OUTPUT_BITS),
          .PULSEWIDTH_BITS(PULSEWIDTH_BITS)
        ) pulse(
          .accumulator(accumulator[ACCUMULATOR_BITS-1:0]),
          .dout(wave_out),
          .pulse_width(pulse_width)
        );
    if (WAVEFORM == 4)
      tone_generator_noise #(
        .OUTPUT_BITS(OUTPUT_BITS)
      ) noise(.clk(accumulator[18]), .rst(rst), .dout(wave_out));
  endgenerate

  always @(posedge main_clk) begin
    if (en_sync && sync_source)
      begin
        accumulator <= 0;
      end
    else
      begin
        accumulator <= accumulator[ACCUMULATOR_BITS-1:0] + tone_freq;
      end
  end

  assign accumulator_overflow = (accumulator[ACCUMULATOR_BITS]);  /* used for syncing to other oscillators */
  assign accumulator_msb = accumulator[ACCUMULATOR_BITS-1];

  always @(posedge sample_clk) begin
    dout <= wave_out ^ (2**(OUTPUT_BITS-1));
  end

endmodule

`endif
