/* =====================
 *  amplitude modulator
 * =====================
 *
 * An amplitude modulator; used, for example, to adjust the output volume
 * of the tone generator based on the output of the ADSR envelope generator.
 *
 * Principle of operation:
 *
 * Converts data-in (din) to a signed value (-128..127 instead of 0..255),
 * scales it according to the amplitude input, and then converts the result back 
 * to unsigned again for output.
 *
 */
module amplitude_modulator #(
  parameter DATA_BITS = 12,
  parameter AMPLITUDE_BITS = 8
)
(
  input [DATA_BITS-1:0]       din,
  input [AMPLITUDE_BITS-1:0]  amplitude,
  input                       clk,
  output wire [DATA_BITS-1:0]  dout
);

  localparam D_SIGNED_BITMASK = (2 ** (DATA_BITS-1));

  // cajole amplitude into a signed value so that verilog
  // uses signed arithmetic in the multiply below
  wire signed [AMPLITUDE_BITS:0] amp_signed;
  assign amp_signed = { 1'b0, amplitude[AMPLITUDE_BITS-1:0] }; // amplitude with extra MSB (0)

  // convert din to a signed value (toggle MSB)
  wire signed [DATA_BITS-1:0] din_signed;
  assign din_signed = din ^ D_SIGNED_BITMASK;  // din_signed = -128..127 instead of 0..255

  reg signed [DATA_BITS+AMPLITUDE_BITS-1:0] scaled_din;  // intermediate value with extended precision

  always @(posedge clk) begin
    scaled_din = (din_signed * amp_signed);
  end

  assign dout = scaled_din[DATA_BITS+AMPLITUDE_BITS-1 -: DATA_BITS] ^ D_SIGNED_BITMASK;

endmodule
