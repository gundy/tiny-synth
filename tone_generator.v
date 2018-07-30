/*
 * Phase-accumulator tone-generator modelled loosely on 6581 SID chip
 */
module tone_generator #(
  parameter FREQ_BITS = 16,
  parameter PULSEWIDTH_BITS = 12,
  parameter OUTPUT_BITS = 12,
  parameter ACCUMULATOR_BITS = 24
)
(
  input [FREQ_BITS-1:0] tone_freq,
  input [3:0] waveform_enable,
  input [PULSEWIDTH_BITS-1:0] pulse_width,
  input clk,
  input rst,
  output wire [OUTPUT_BITS-1:0] dout,
  output wire accumulator_msb,
  input ringmod_enable,
  input wire ringmod_source
);

  reg [ACCUMULATOR_BITS-1:0] accumulator;
  reg [OUTPUT_BITS-1:0] wave_tri_out;

  wire [OUTPUT_BITS-1:0] noise_dout;
  tone_generator_noise noise(.clk(accumulator[19]), .rst(rst), .dout(noise_dout));

  reg [OUTPUT_BITS-1:0] val;

  always @(posedge clk) begin

    accumulator <= accumulator + tone_freq;

    val = (2**OUTPUT_BITS)-1;

    if (waveform_enable[3] == 1) // NOISE
      begin
        val = val & noise_dout;
      end

    if (waveform_enable[2] == 1) // PULSE
      begin
        if (accumulator[ACCUMULATOR_BITS-1 -: PULSEWIDTH_BITS] > pulse_width)
          begin
            val = val & ((2 ** OUTPUT_BITS) - 1);
          end
        else
          begin
            val = 0;
          end
      end

    if (waveform_enable[1] == 1) // SAW
      begin
        // output is simply the MSB of the accumulator
        val = val & accumulator[ACCUMULATOR_BITS-1 -: OUTPUT_BITS];
      end

    if (waveform_enable[0] == 1) // TRIANGLE
      begin
      if (!ringmod_enable && accumulator[ACCUMULATOR_BITS-1] == 0 || ringmod_enable && !ringmod_source)
        begin
          // MSB not set; we're in the rising part of the triangle waveform, do not invert
          val = val & accumulator[ACCUMULATOR_BITS-2:(ACCUMULATOR_BITS-2)-(OUTPUT_BITS-1)];
        end
      else
        begin
          // MSB is set; we need to invert waveform
          val = val & ~accumulator[ACCUMULATOR_BITS-2:(ACCUMULATOR_BITS-2)-(OUTPUT_BITS-1)];
        end
      end
  end
  assign dout = val;

endmodule
