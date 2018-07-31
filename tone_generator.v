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
  input [PULSEWIDTH_BITS-1:0] pulse_width,
  input clk,
  input rst,
  output wire [OUTPUT_BITS-1:0] dout,
  output wire accumulator_msb,
  output wire accumulator_overflow,

  input wire en_ringmod,
  input wire ringmod_source,

  input wire en_sync,
  input wire sync_source,

  input en_noise,
  input en_pulse,
  input en_triangle,
  input en_saw);

  reg [ACCUMULATOR_BITS:0] accumulator;

  wire [OUTPUT_BITS-1:0] noise_dout;
  tone_generator_noise #(
    .OUTPUT_BITS(OUTPUT_BITS)
  ) noise(.clk(accumulator[19]), .rst(rst), .dout(noise_dout));

  wire [OUTPUT_BITS-1:0] triangle_dout;
  tone_generator_triangle #(
      .ACCUMULATOR_BITS(ACCUMULATOR_BITS),
      .OUTPUT_BITS(OUTPUT_BITS)
  ) triangle_generator (
      .accumulator(accumulator[ACCUMULATOR_BITS-1:0]),
      .dout(triangle_dout),
      .en_ringmod(en_ringmod),
      .ringmod_source(ringmod_source)
    );

  wire [OUTPUT_BITS-1:0] saw_dout;
  tone_generator_saw  #(
      .ACCUMULATOR_BITS(ACCUMULATOR_BITS),
      .OUTPUT_BITS(OUTPUT_BITS)
    ) saw(
      .accumulator(accumulator[ACCUMULATOR_BITS-1:0]),
      .dout(saw_dout)
    );

  wire [OUTPUT_BITS-1:0] pulse_dout;
  tone_generator_pulse  #(
      .ACCUMULATOR_BITS(ACCUMULATOR_BITS),
      .OUTPUT_BITS(OUTPUT_BITS),
      .PULSEWIDTH_BITS(PULSEWIDTH_BITS)
    ) pulse(
      .accumulator(accumulator[ACCUMULATOR_BITS-1:0]),
      .dout(pulse_dout),
      .pulse_width(pulse_width)
    );

  reg [OUTPUT_BITS-1:0] dout_tmp;

  always @(posedge clk) begin
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

  always @(posedge clk) begin
    dout_tmp = (2**OUTPUT_BITS)-1;
    if (en_noise)
      dout_tmp = dout_tmp & noise_dout;
    if (en_saw)
      dout_tmp = dout_tmp & saw_dout;
    if (en_triangle)
      dout_tmp = dout_tmp & triangle_dout;
    if (en_pulse)
      dout_tmp = dout_tmp & pulse_dout;
  end

  assign dout = dout_tmp;

endmodule
