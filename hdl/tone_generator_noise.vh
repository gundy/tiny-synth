`ifndef __TINY_SYNTH_TONE_NOISE__
`define __TINY_SYNTH_TONE_NOISE__

/* ============================
 * Random noise tone generator
 * ============================
 *
 * This module creates a pseudo-random stream of noise at the rate of clk.
 *
 * out_data is 12-bit noise that is behaviourally similar to what the 6581
 * SID chip would produce.
 *
 * By varying the speed of the clk input, the pitch of the generated
 * noise can be varied.
 *
 * Principle of operation:
 *
 * The noise output is taken from intermediate bits of a 23-bit shift register
 *  Operation: Calculate XOR result, shift register, set bit 0 = result.
 *
 *                       ----------------------->---------------------
 *                       |                                            |
 *                   ----EOR----                                      |
 *                   |         |                                      |
 *                   2 2 2 1 1 1 1 1 1 1 1 1 1                        |
 * Register bits:    2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 <---
 *                   |   |       |     |   |       |     |   |
 *  out bits  :      7   6       5     4   3       2     1   0
 *
 * The 8-bits extracted from the shift register are then left-aligned
 *  in the output bits.
 *
 * Note: Because of the way this works; if all of the bits in the shift
 *       register somehow become zero's, the output will stay zero
 *       permanently (0 XOR 0 => 0).
 *
 *       For that reason the shfit register is initially seeded with a
 *       "random" (key mashed, static) value, and can be reset with the rst
 *       input if required.
 */
module tone_generator_noise #(
  parameter OUTPUT_BITS = 12
)(
  input clk,
  input rst,
  output wire [OUTPUT_BITS-1:0] dout);

  reg [22:0] lsfr = 23'b01101110010010000101011;

  always @(posedge clk or posedge rst) begin
    if (rst)
      begin
        lsfr <= 23'b01101110010010000101011;
      end
    else
      begin
        lsfr <= { lsfr[21:0], lsfr[22] ^ lsfr[17] };
    end
  end

  assign dout = { lsfr[22], lsfr[20], lsfr[16], lsfr[13], lsfr[11], lsfr[7], lsfr[4], lsfr[2], {(OUTPUT_BITS-8){1'b0}} };

endmodule

`endif
