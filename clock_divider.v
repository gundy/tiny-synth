module clock_divider #(
  parameter DIVISOR = 28'd2
)
(
  input wire cin,
  output wire cout
);

localparam FULL_SCALE = 2 ** 28;
localparam [27:0] INCREMENT = $rtoi(FULL_SCALE / DIVISOR);

reg [27:0] counter;

always @(posedge cin)
begin
  counter <= counter + INCREMENT;
end

assign cout = counter[27];

endmodule
