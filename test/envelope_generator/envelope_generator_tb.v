//-------------------------------------------------------------------
//-- Testbench for the tiny-synth clock divider module
//-------------------------------------------------------------------
`default_nettype none
`timescale 100ns / 10ns

`include "envelope_generator.v"

module envelope_generator_tb();

  //-- Simulation time: Duration * 1us (timescale above)
  parameter DURATION = 88200;  // 2 second worth of samples

  //-- Clock signal. Running at 1MHz
  reg clkin = 0;
  always #0.5 clkin = ~clkin;

  reg gate = 1;
  always #22050 gate = 0;

  wire[7:0] envelope;

  envelope_generator DUT(
    .rst(1'b0),
    .clk(clkin),
    .gate(gate),
    .a(4'd4), .d(4'd4), .s(4'd8), .r(4'd4),
    .amplitude(envelope)
  );

  initial begin

    //-- File were to store the simulation results
    $dumpfile("envelope_generator_tb.vcd");
    $dumpvars(0, envelope_generator_tb);

     #(DURATION) $display("End of simulation");
    $finish;
  end

endmodule
