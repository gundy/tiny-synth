//-------------------------------------------------------------------
//-- Testbench for the tiny-synth clock divider module
//-------------------------------------------------------------------
`default_nettype none
`timescale 100 ns / 10 ns

module filter_ewma_tb();

//-- Simulation time: Duration * 0.1us (timescale above)
parameter DURATION = 1000;  // 1000 = 0.1 milliseconds

//-- Clock signal. Running at 1MHz
reg clkin = 0;
always #0.5 clkin = ~clkin;

wire sq_wave_clk;
wire signed [11:0] sq_wave_sig;

clock_divider #(.DIVISOR(128)) cdiv_sq(.cin(clkin), .cout(sq_wave_clk));

assign sq_wave_sig = sq_wave_clk ? -12'd2048 : 12'd2047;

wire signed [11:0] filter_out;
filter_ewma moving_average_filter(.clk(clkin), .s_alpha($signed(9'd30)), .din(sq_wave_sig), .dout(filter_out));

initial begin

  //-- File were to store the simulation results
  $dumpfile("filter_ewma_tb.vcd");
  $dumpvars(0, filter_ewma_tb);

   #(DURATION) $display("End of simulation");
  $finish;
end

endmodule
