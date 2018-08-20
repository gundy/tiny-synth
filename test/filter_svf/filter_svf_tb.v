//-------------------------------------------------------------------
//-- Testbench for the tiny-synth clock divider module
//-------------------------------------------------------------------
`default_nettype none
`timescale 100 ns / 10 ns

module filter_svf_tb();

//-- Simulation time: Duration * 0.1us (timescale above)
parameter DURATION = 1000;  // 1000 = 0.1 milliseconds

//-- Clock signal. Running at 1MHz
reg clkin = 0;
always #0.5 clkin = ~clkin;

wire sq_wave_clk;
wire signed [11:0] sq_wave_sig;

clock_divider #(.DIVISOR(128)) cdiv_sq(.cin(clkin), .cout(sq_wave_clk));

assign sq_wave_sig = sq_wave_clk ? -12'd400 : 12'd400;

wire signed [11:0] high_pass_out;
wire signed [11:0] low_pass_out;
wire signed [11:0] band_pass_out;
wire signed [11:0] notch_pass_out;

localparam Q = 4.0;
localparam Q1 = 1.0/Q;
localparam Q1_fixed_point = $rtoi(Q1 * (2**16));

localparam F = 0.4;
localparam F_fixed_point = $rtoi(F * (2**17));

filter_svf state_variable_filter(
  .clk(clkin),
  .F(F_fixed_point),
  .Q1(Q1_fixed_point),
  .in(sq_wave_sig),
  .out_highpass(high_pass_out),
  .out_lowpass(low_pass_out),
  .out_bandpass(band_pass_out),
  .out_notch(notch_pass_out)
  );

initial begin

  //-- File were to store the simulation results
  $dumpfile("filter_svf_tb.vcd");
  $dumpvars(0, filter_svf_tb);

   #(DURATION) $display("End of simulation");
  $finish;
end

endmodule
