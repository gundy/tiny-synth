`ifndef __TINY_SYNTH_MULTI_CHANNEL_MIXER__
`define __TINY_SYNTH_MULTI_CHANNEL_MIXER__

/* ===================
 * Two-into-one mixer
 * ===================
 *
 * Mixes up to 12 input signals into a single output.
 */
module multi_channel_mixer #(
  parameter DATA_BITS = 12,
  parameter ACTIVE_CHANNELS = 2
)
(
  input clk,
  input signed [DATA_BITS-1:0] a,
  input signed [DATA_BITS-1:0] b,
  input signed [DATA_BITS-1:0] c,
  input signed [DATA_BITS-1:0] d,
  input signed [DATA_BITS-1:0] e,
  input signed [DATA_BITS-1:0] f,
  input signed [DATA_BITS-1:0] g,
  input signed [DATA_BITS-1:0] h,
  input signed [DATA_BITS-1:0] i,
  input signed [DATA_BITS-1:0] j,
  input signed [DATA_BITS-1:0] k,
  input signed [DATA_BITS-1:0] l,
  output signed [DATA_BITS-1:0] dout
);

  localparam EXTRA_BITS_REQUIRED = $clog2(ACTIVE_CHANNELS);

  wire signed [DATA_BITS+4:0] sum;

  localparam MIN_VALUE = -(2**(DATA_BITS-1));
  localparam MAX_VALUE = (2**(DATA_BITS-1))-1;

  assign sum = (a+b+c+d+e+f+g+h+i+j+k+l) >>> EXTRA_BITS_REQUIRED;
  assign dout = (sum < MIN_VALUE)
                ? MIN_VALUE :
                  (sum > MAX_VALUE ?
                      MAX_VALUE
                      : sum);

endmodule

`endif
