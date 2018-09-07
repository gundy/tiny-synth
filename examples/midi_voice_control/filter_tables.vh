`ifndef __FILTER_TABLES__
`define __FILTER_TABLES__

module f_table(
  input clk,
  input [6:0] val,
  output reg signed [17:0] result);

  reg[17:0] LOOKUP_TABLE[0:127];
  initial $readmemh ("f_table.mem", LOOKUP_TABLE);

  always @(posedge clk) begin
    result <= LOOKUP_TABLE[val];
  end
endmodule

module q1_table(
  input clk,
  input [6:0] val,
  output reg signed [17:0] result);

  reg[17:0] LOOKUP_TABLE[0:127];
  initial $readmemh ("q1_table.mem", LOOKUP_TABLE);

  always @(posedge clk) begin
    result <= LOOKUP_TABLE[val];
  end
endmodule


`endif
