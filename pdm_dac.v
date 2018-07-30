module pdm_dac #(parameter DATA_BITS = 12)(
  input [DATA_BITS-1:0] din,
  input wire clk,
  output wire dout
);

reg [DATA_BITS:0] accumulator;

always @(posedge clk) begin
  accumulator <= (accumulator[DATA_BITS-1 : 0] + din);
end

assign dout = accumulator[DATA_BITS];

endmodule
