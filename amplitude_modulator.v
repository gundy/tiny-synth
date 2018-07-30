

module amplitude_modulator #(
  parameter DATA_BITS = 12,
  parameter AMPLITUDE_BITS = 8
)
(
  input [DATA_BITS-1:0]       din,
  input [AMPLITUDE_BITS-1:0]  amplitude,
  input                       clk,
  output reg [DATA_BITS-1:0]  dout
);

  localparam D_SIGNED_BITMASK = (2 ** (DATA_BITS-1));

  reg signed [AMPLITUDE_BITS:0] signed_amp;
  reg signed [DATA_BITS-1:0] din_signed;
  reg signed [DATA_BITS-1:0] dout_signed;
  always @* begin
    din_signed = din ^ D_SIGNED_BITMASK;
    signed_amp = { 1'b0, amplitude[AMPLITUDE_BITS-1:0] };
  end

  reg signed [DATA_BITS+AMPLITUDE_BITS-1:0] scaled_din;

  always @(posedge clk) begin
    scaled_din = (din_signed * signed_amp);
    dout_signed = scaled_din[DATA_BITS+AMPLITUDE_BITS-1 -: DATA_BITS];
    dout = dout_signed ^ D_SIGNED_BITMASK;
  end
endmodule
