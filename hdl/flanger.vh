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
   input wire signed [SAMPLE_BITS-1:0] din,
   output reg signed [SAMPLE_BITS-1:0] dout
 );

 localparam DELAY_BUFFER_LENGTH = 2**DELAY_BUFFER_LENGTH_BITS;
 localparam DELAY_BUFFER_MAX = DELAY_BUFFER_LENGTH-1;

 localparam SAMPLE_HIGH_BIT = 2**(SAMPLE_BITS-1);

// reg [SAMPLE_BITS-1:0] delay_buffer [0:DELAY_BUFFER_LENGTH-1];

 // top bits of accumulator give us our current tap point in the delay buffer
 reg [ACCUMULATOR_BITS-1:0] accumulator;
 reg [7:0] delay_buffer_write_address;

 reg signed [SAMPLE_BITS-1:0] delay_tap_output;
 reg[7:0] delay_buffer_read_address;
 wire [DELAY_BUFFER_LENGTH_BITS-1:0] delay_buffer_tap_index;  /* output of triangle oscillator */
 assign delay_buffer_tap_index = (accumulator[ACCUMULATOR_BITS-1]==1'b1)
                         ? ~accumulator[(ACCUMULATOR_BITS-2) -: DELAY_BUFFER_LENGTH_BITS]
                         :  accumulator[(ACCUMULATOR_BITS-2) -: DELAY_BUFFER_LENGTH_BITS];

 assign delay_buffer_read_address = ((delay_buffer_write_address-delay_buffer_tap_index)&DELAY_BUFFER_MAX);

 // WRITE_MODE = 0 and READ_MODE = 0 configures this as a 256 x 16-bit RAM
 SB_RAM40_4K #(.WRITE_MODE(0), .READ_MODE(0)) delay_buffer (
   // read side of buffer; serial port to FPGA
   .RDATA(delay_tap_output),
   .RADDR(delay_buffer_read_address),
   .RCLK(sample_clk),
   .RE(1'b1),

   // write side of buffer; FPGA to serial port
   .WADDR(delay_buffer_write_address),
   .WCLK(sample_clk),
   .WDATA(din),
   .WE(1'b1)
 );

initial
begin
  accumulator = 0;
  delay_buffer_write_address = 0;
end

localparam ACCUMULATOR_MAX_SCALE = 2**ACCUMULATOR_BITS;
localparam ACCUMULATOR_PHASE_INCREMENT = $rtoi((ACCUMULATOR_MAX_SCALE * FLANGE_RATE) / 44100);

reg signed [SAMPLE_BITS:0] tmp;

always @(posedge sample_clk)
begin

  // write current sample into delay buffer
  delay_buffer_write_address <= delay_buffer_write_address + 1;
  accumulator <= accumulator + ACCUMULATOR_PHASE_INCREMENT;

  tmp = din + delay_tap_output;
  dout <= tmp >>> 1;
end


endmodule
