/* ========================================================
 * Flanger
 * ========================================================
 *
 * This module implements a simple flanger effect.
 *
 * Principle of operation:
 *
 * A flanger works by mixing the input with a delayed version
 * of itself - where the delay length is, itself, modulated.
 *
 * In this instance, we use an ICE40 SPRAM block as storage
 * for the delay line, and use a triangle-wave modulator for
 * the length of the line.
 *
 * The line can be any length up to 256 entries  - the following table
 * shows the different lengths and their equivalent times in milliseconds
 * at a 44.1kHz sample rate:
 *
 * 256 -> 5.8ms
 * 128 -> 2.9ms
 * 64 -> 1.45ms
 * 32 -> 0.7ms
 * ...
 *
 */

 module flanger #(
  parameter DELAY_BUFFER_LENGTH_BITS = 8,  /* = 8-bits = 256 long = 5.6 milliseconds @ 44.1kHz */
  parameter SAMPLE_BITS = 12,
  parameter SAMPLE_RATE = 44100, /* Hz */
  parameter FLANGE_RATE = 1.2,   /* Hz */
  parameter ACCUMULATOR_BITS = 21
 )
 (
   input wire sample_clk,
   input wire [SAMPLE_BITS-1:0] din,
   output reg [SAMPLE_BITS-1:0] dout
 );

// top bits of accumulator give us our current tap point in the delay buffer
reg [ACCUMULATOR_BITS-1:0] accumulator;
reg [7:0] delay_buffer_write_idx;

localparam DELAY_BUFFER_LENGTH = 2**DELAY_BUFFER_LENGTH_BITS;
localparam DELAY_BUFFER_MAX = DELAY_BUFFER_LENGTH-1;

localparam SAMPLE_HIGH_BIT = 2**(SAMPLE_BITS-1);

reg [SAMPLE_BITS-1:0] delay_buffer [0:DELAY_BUFFER_LENGTH-1];

initial
begin
  accumulator = 0;
  delay_buffer_write_idx = 0;
end

localparam ACCUMULATOR_MAX_SCALE = 2**ACCUMULATOR_BITS;
localparam ACCUMULATOR_PHASE_INCREMENT = $rtoi((ACCUMULATOR_MAX_SCALE * FLANGE_RATE) / 44100);

reg [DELAY_BUFFER_LENGTH_BITS-1:0] delay_buffer_tap_index;

reg [SAMPLE_BITS:0] tmp;

always @(posedge sample_clk)
begin
  delay_buffer_tap_index <= (accumulator[ACCUMULATOR_BITS-1]==1'b1)
                          ? ~accumulator[(ACCUMULATOR_BITS-2) -: DELAY_BUFFER_LENGTH_BITS]
                          :  accumulator[(ACCUMULATOR_BITS-2) -: DELAY_BUFFER_LENGTH_BITS];

  // write current sample into delay buffer
  delay_buffer_write_idx <= delay_buffer_write_idx + 1;
  delay_buffer[delay_buffer_write_idx] <= din;

  accumulator <= accumulator + ACCUMULATOR_PHASE_INCREMENT;
  tmp = din + delay_buffer[(delay_buffer_write_idx-1-delay_buffer_tap_index)&DELAY_BUFFER_MAX];
  dout <= tmp >> 1;
end


endmodule
