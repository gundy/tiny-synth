`ifndef __TINY_SYNTH_FILTER_EWMA__
`define __TINY_SYNTH_FILTER_EWMA__
/* ========================================================
 * Exponentially weighted moving average (low-pass) filter
 * ========================================================
 *
 * This module implements a simple single-multiply exponentially
 * weighted moving average (EWMA) low-pass filter.
 *
 * Principle of operation:
 *
 * This filter is well described by Rick Lyons in his article
 *  here - refer to diagram 1b:
 *
 * https://www.dsprelated.com/showarticle/182.php
 *
 * This filter has a single parameter, alpha, that can be used to
 * control the cut-off frequency.
 *
 * Use the following formula to calculate alpha based on desired -3dB cut-off:
 *
 * Fs = sample rate
 * Fc = cutoff frequency
 * b = cos(2*pi*Fc / Fs);
 *
 * alpha = 255 * b - 1 + sqrt(b^2 - 4*b + 3);
 */

 /* Example values for alpha based on Fc/Fs:
  *
  * ===================
  * Fc(-3dB)/Fs   alpha
  * -------------------
  *        0.01,  16
  *        0.02,  30
  *        0.03,  44
  *        0.04,  56
  *        0.05,  68
  *        0.06,  79
  *        0.07,  90
  *        0.08,  99
  *        0.09, 108
  *        0.09, 116
  *        0.10, 124
  *        0.11, 131
  *        0.12, 137
  *        0.13, 144
  *        0.15, 149
  *        0.16, 154
  *        0.17, 159
  *        0.18, 164
  *        0.19, 168
  *        0.20, 172
  *        0.21, 175
  *        0.22, 178
  *        0.23, 181
  *        0.24, 184
  *        0.25, 187
  *        0.26, 189
  *        0.27, 191
  *        0.28, 193
  *        0.29, 195
  *        0.30, 197
  *        0.31, 199
  *        0.32, 200
  */

module filter_ewma (
  input clk,
  input wire signed [8:0] s_alpha,
  input wire unsigned [11:0] din,  /* unfiltered data in */
  output reg unsigned [11:0] dout  /* filtered data out */
);


initial
begin
  dout = 2047;
  s_din = 2047;
  s_delayed_dout = 2047;
  s_adder1_out = 2047;
end

reg signed [11:0] s_delayed_dout;
reg signed [12:0] s_adder1_out;
reg signed [21:0] sw_raw_mul_output;
reg signed [12:0] s_mul_out;
reg signed [12:0] tmp_dout;
reg signed [11:0] s_din;

always @(posedge clk)
begin
  // copy previous dout to delay line
  s_delayed_dout = dout ^ 12'd2048;
  s_din = din ^ 12'd2048;
  s_adder1_out = s_din - s_delayed_dout;
  sw_raw_mul_output = (s_adder1_out * s_alpha) >>> 8;  // divide by 256 (amplitude)
  s_mul_out = sw_raw_mul_output[12:0];
  tmp_dout = (s_mul_out + s_delayed_dout);
  dout = tmp_dout[11:0] ^ 12'd2048;
end

endmodule

`endif
