`ifndef __TINY_SYNTH_TWO_INTO_ONE_MIXER__
`define __TINY_SYNTH_TWO_INTO_ONE_MIXER__

/* ===================
 * Two-into-one mixer
 * ===================
 *
 * Mixes two input signals into a single output.
 */
module two_into_one_mixer #(
  parameter DATA_BITS = 12
)
(
  input signed [DATA_BITS-1:0] a,
  input signed [DATA_BITS-1:0] b,
  output signed [DATA_BITS-1:0] dout
);

  wire signed [DATA_BITS:0] intermediate;

  assign intermediate = a+b;

  assign dout = intermediate >>> 1;

endmodule

`endif
