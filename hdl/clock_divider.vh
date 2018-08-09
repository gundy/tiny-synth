`ifndef __TINY_SYNTH_CLOCK_DIVIDER__
`define __TINY_SYNTH_CLOCK_DIVIDER__

module clock_divider #(
  parameter DIVISOR = 2
)
(
  input wire cin,
  output wire cout
);

localparam FULL_SCALE = 2 ** 28;
localparam [27:0] INCREMENT = $rtoi(FULL_SCALE / DIVISOR);

reg [27:0] counter;

initial begin
  counter = 0;
end

always @(posedge cin)
begin
  counter = counter + INCREMENT;
end

assign cout = counter[27];

endmodule

`endif
