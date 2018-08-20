`ifndef __TINY_SYNTH_SVF__
`define __TINY_SYNTH_SVF__

/*
 * State variable filter:
 *  Ref: Musical applications of microprocessors - Chamberlain: pp489+
 *
 * This filter provides high-pass, low-pass, band-pass and notch-pass outputs.
 *
 * Tuning parameters are F (frequency), and Q1 of the filter.
 *
 * The relation between F, the cut-off frequency Fc,
 * and the sampling rate, Fs, is approximated by the formula:
 *
 * F = 2π*Fc/Fs
 *
 * F is a 1.17 fixed-point value, and at a sample rate of 250kHz,
 * F ranges from approximately 0.00050 (10Hz) -> ~0.55 (22kHz).
 *
 * Q1 controls the Q (resonance) of the filter.  Q1 is equivalent to 1/Q.
 * Q1 ranges from 2 (corresponding to a Q value of 0.5) down to 0 (Q = infinity)
 */

module filter_svf #(
  parameter SAMPLE_BITS = 12
)(
  input  clk,
  input  signed [SAMPLE_BITS-1:0] in,
  output signed [SAMPLE_BITS-1:0] out_highpass,
  output signed [SAMPLE_BITS-1:0] out_lowpass,
  output signed [SAMPLE_BITS-1:0] out_bandpass,
  output signed [SAMPLE_BITS-1:0] out_notch,
  input  signed [17:0] F,  /* F1: frequency control; fixed point 1.17  ; F = 2π*Fc/Fs.  At a sample rate of 250kHz, F ranges from 0.00050 (10Hz) -> ~0.55 (22kHz) */
  input  signed [17:0] Q1  /* Q1: Q control;         fixed point 2.16  ; Q1 = 1/Q        Q1 ranges from 2 (Q=0.5) to 0 (Q = infinity). */
);


  reg signed[SAMPLE_BITS+2:0] highpass;
  reg signed[SAMPLE_BITS+2:0] lowpass;
  reg signed[SAMPLE_BITS+2:0] bandpass;
  reg signed[SAMPLE_BITS+2:0] notch;
  reg signed[SAMPLE_BITS+2:0] in_sign_extended;

  localparam signed [SAMPLE_BITS:0] MAX = (2**(SAMPLE_BITS-1))-1;
  localparam signed [SAMPLE_BITS:0] MIN = -(2**(SAMPLE_BITS-1));

  `define CLAMP(x) ((x>MAX)?MAX:((x<MIN)?MIN:x[SAMPLE_BITS-1:0]))

  assign out_highpass = `CLAMP(highpass);
  assign out_lowpass = `CLAMP(lowpass);
  assign out_bandpass = `CLAMP(bandpass);
  assign out_notch = `CLAMP(notch);

  // intermediate values from multipliers
  reg signed [34:0] Q1_scaled_delayed_bandpass;
  reg signed [34:0] F_scaled_delayed_bandpass;
  reg signed [34:0] F_scaled_highpass;



  initial begin
    highpass = 0;
    lowpass = 0;
    bandpass = 0;
    notch = 0;
  end

  always @(posedge clk) begin
    in_sign_extended = { {3{in[SAMPLE_BITS-1]}}, in};
    Q1_scaled_delayed_bandpass = (bandpass * Q1) >>> 16;
    F_scaled_delayed_bandpass = (bandpass * F) >>> 17;
    lowpass = lowpass + F_scaled_delayed_bandpass[SAMPLE_BITS+2:0];
    highpass = in_sign_extended - Q1_scaled_delayed_bandpass[SAMPLE_BITS+2:0] - lowpass;
    F_scaled_highpass = (highpass * F) >>> 17;
    bandpass = F_scaled_highpass[SAMPLE_BITS+2:0] + bandpass;
    notch = highpass + lowpass;
  end

endmodule

`endif
