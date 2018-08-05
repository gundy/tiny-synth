//-------------------------------------------------------------------
//-- Testbench for the tiny-synth clock divider module
//-------------------------------------------------------------------
`default_nettype none
`timescale 100 ns / 10 ns

module clock_divider_tb();

//-- Simulation time: 1us (10 * 100ns)
parameter DURATION = 100;

//-- Clock signal. Running at 1MHz
reg clkin = 0;
always #0.5 clkin = ~clkin;

wire clkoutdiv1, clkoutdiv2, clkoutdiv3, clkoutdiv4, clkoutdiv5, clkoutdiv6, clkoutdiv7, clkoutdiv8;

//-- Instantiate the unit to test
//clock_divider #(.DIVISOR(1)) UUT1(clkin, clkoutdiv1);
clock_divider #(.DIVISOR(2)) UUT2(clkin, clkoutdiv2);
clock_divider #(.DIVISOR(3)) UUT3(clkin, clkoutdiv3);
clock_divider #(.DIVISOR(4)) UUT4(clkin, clkoutdiv4);
clock_divider #(.DIVISOR(5)) UUT5(clkin, clkoutdiv5);
clock_divider #(.DIVISOR(6)) UUT6(clkin, clkoutdiv6);
clock_divider #(.DIVISOR(7)) UUT7(clkin, clkoutdiv7);
clock_divider #(.DIVISOR(8)) UUT8(clkin, clkoutdiv8);

initial begin

  //-- File were to store the simulation results
  $dumpfile("clock_divider_tb.vcd");
  $dumpvars(0, clock_divider_tb);

   #(DURATION) $display("End of simulation");
  $finish;
end

endmodule
