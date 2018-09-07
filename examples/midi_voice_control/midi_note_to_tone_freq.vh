`ifndef __TINY_SYNTH_MIDI_NOTE_TO_TONE_FREQ__
`define __TINY_SYNTH_MIDI_NOTE_TO_TONE_FREQ__

function [15:0] midi_note_to_tone_freq
(
  input [7:0] midi_note
);

  case (midi_note)
    8'h00: midi_note_to_tone_freq = 16'h0089;
    8'h01: midi_note_to_tone_freq = 16'h0091;
    8'h02: midi_note_to_tone_freq = 16'h0099;
    8'h03: midi_note_to_tone_freq = 16'h00a3;
    8'h04: midi_note_to_tone_freq = 16'h00ac;
    8'h05: midi_note_to_tone_freq = 16'h00b7;
    8'h06: midi_note_to_tone_freq = 16'h00c1;
    8'h07: midi_note_to_tone_freq = 16'h00cd;
    8'h08: midi_note_to_tone_freq = 16'h00d9;
    8'h09: midi_note_to_tone_freq = 16'h00e6;
    8'h0a: midi_note_to_tone_freq = 16'h00f4;
    8'h0b: midi_note_to_tone_freq = 16'h0102;
    8'h0c: midi_note_to_tone_freq = 16'h0112;
    8'h0d: midi_note_to_tone_freq = 16'h0122;
    8'h0e: midi_note_to_tone_freq = 16'h0133;
    8'h0f: midi_note_to_tone_freq = 16'h0146;
    8'h10: midi_note_to_tone_freq = 16'h0159;
    8'h11: midi_note_to_tone_freq = 16'h016e;
    8'h12: midi_note_to_tone_freq = 16'h0183;
    8'h13: midi_note_to_tone_freq = 16'h019b;
    8'h14: midi_note_to_tone_freq = 16'h01b3;
    8'h15: midi_note_to_tone_freq = 16'h01cd;
    8'h16: midi_note_to_tone_freq = 16'h01e8;
    8'h17: midi_note_to_tone_freq = 16'h0205;
    8'h18: midi_note_to_tone_freq = 16'h0224;
    8'h19: midi_note_to_tone_freq = 16'h0245;
    8'h1a: midi_note_to_tone_freq = 16'h0267;
    8'h1b: midi_note_to_tone_freq = 16'h028c;
    8'h1c: midi_note_to_tone_freq = 16'h02b3;
    8'h1d: midi_note_to_tone_freq = 16'h02dc;
    8'h1e: midi_note_to_tone_freq = 16'h0307;
    8'h1f: midi_note_to_tone_freq = 16'h0336;
    8'h20: midi_note_to_tone_freq = 16'h0366;
    8'h21: midi_note_to_tone_freq = 16'h039a;
    8'h22: midi_note_to_tone_freq = 16'h03d1;
    8'h23: midi_note_to_tone_freq = 16'h040b;
    8'h24: midi_note_to_tone_freq = 16'h0449;
    8'h25: midi_note_to_tone_freq = 16'h048a;
    8'h26: midi_note_to_tone_freq = 16'h04cf;
    8'h27: midi_note_to_tone_freq = 16'h0518;
    8'h28: midi_note_to_tone_freq = 16'h0566;
    8'h29: midi_note_to_tone_freq = 16'h05b8;
    8'h2a: midi_note_to_tone_freq = 16'h060f;
    8'h2b: midi_note_to_tone_freq = 16'h066c;
    8'h2c: midi_note_to_tone_freq = 16'h06cd;
    8'h2d: midi_note_to_tone_freq = 16'h0735;
    8'h2e: midi_note_to_tone_freq = 16'h07a3;
    8'h2f: midi_note_to_tone_freq = 16'h0817;
    8'h30: midi_note_to_tone_freq = 16'h0892;
    8'h31: midi_note_to_tone_freq = 16'h0915;
    8'h32: midi_note_to_tone_freq = 16'h099f;
    8'h33: midi_note_to_tone_freq = 16'h0a31;
    8'h34: midi_note_to_tone_freq = 16'h0acd;
    8'h35: midi_note_to_tone_freq = 16'h0b71;
    8'h36: midi_note_to_tone_freq = 16'h0c1f;
    8'h37: midi_note_to_tone_freq = 16'h0cd8;
    8'h38: midi_note_to_tone_freq = 16'h0d9b;
    8'h39: midi_note_to_tone_freq = 16'h0e6a;
    8'h3a: midi_note_to_tone_freq = 16'h0f46;
    8'h3b: midi_note_to_tone_freq = 16'h102e;
    8'h3c: midi_note_to_tone_freq = 16'h1125;  /* middle C */
    8'h3d: midi_note_to_tone_freq = 16'h122a;
    8'h3e: midi_note_to_tone_freq = 16'h133e;
    8'h3f: midi_note_to_tone_freq = 16'h1463;
    8'h40: midi_note_to_tone_freq = 16'h159a;
    8'h41: midi_note_to_tone_freq = 16'h16e2;
    8'h42: midi_note_to_tone_freq = 16'h183f;
    8'h43: midi_note_to_tone_freq = 16'h19b0;
    8'h44: midi_note_to_tone_freq = 16'h1b37;
    8'h45: midi_note_to_tone_freq = 16'h1cd5;
    8'h46: midi_note_to_tone_freq = 16'h1e8c;
    8'h47: midi_note_to_tone_freq = 16'h205d;
    8'h48: midi_note_to_tone_freq = 16'h224a;
    8'h49: midi_note_to_tone_freq = 16'h2454;
    8'h4a: midi_note_to_tone_freq = 16'h267d;
    8'h4b: midi_note_to_tone_freq = 16'h28c7;
    8'h4c: midi_note_to_tone_freq = 16'h2b34;
    8'h4d: midi_note_to_tone_freq = 16'h2dc5;
    8'h4e: midi_note_to_tone_freq = 16'h307e;
    8'h4f: midi_note_to_tone_freq = 16'h3360;
    8'h50: midi_note_to_tone_freq = 16'h366f;
    8'h51: midi_note_to_tone_freq = 16'h39ab;
    8'h52: midi_note_to_tone_freq = 16'h3d19;
    8'h53: midi_note_to_tone_freq = 16'h40bb;
    8'h54: midi_note_to_tone_freq = 16'h4495;
    8'h55: midi_note_to_tone_freq = 16'h48a8;
    8'h56: midi_note_to_tone_freq = 16'h4cfb;
    8'h57: midi_note_to_tone_freq = 16'h518e;
    8'h58: midi_note_to_tone_freq = 16'h5668;
    8'h59: midi_note_to_tone_freq = 16'h5b8b;
    8'h5a: midi_note_to_tone_freq = 16'h60fd;
    8'h5b: midi_note_to_tone_freq = 16'h66c1;
    8'h5c: midi_note_to_tone_freq = 16'h6cde;
    8'h5d: midi_note_to_tone_freq = 16'h7357;
    8'h5e: midi_note_to_tone_freq = 16'h7a33;
    8'h5f: midi_note_to_tone_freq = 16'h8177;
    8'h60: midi_note_to_tone_freq = 16'h892a;
    8'h61: midi_note_to_tone_freq = 16'h9151;
    8'h62: midi_note_to_tone_freq = 16'h99f6;
    8'h63: midi_note_to_tone_freq = 16'ha31d;
    8'h64: midi_note_to_tone_freq = 16'hacd0;
    8'h65: midi_note_to_tone_freq = 16'hb717;
    8'h66: midi_note_to_tone_freq = 16'hc1fa;
    8'h67: midi_note_to_tone_freq = 16'hcd83;
    8'h68: midi_note_to_tone_freq = 16'hd9bc;
    8'h69: midi_note_to_tone_freq = 16'he6ae;
    8'h6a: midi_note_to_tone_freq = 16'hf466;
    default: midi_note_to_tone_freq = 16'hf466;  // 16-bit increment counter doesn't have resolution for further notes
    // 8'h6b: midi_note_to_tone_freq = 16'h102ee;
    // 8'h6c: midi_note_to_tone_freq = 16'h11254;
    // 8'h6d: midi_note_to_tone_freq = 16'h122a3;
    // 8'h6e: midi_note_to_tone_freq = 16'h133ec;
    // 8'h6f: midi_note_to_tone_freq = 16'h1463b;
    // 8'h70: midi_note_to_tone_freq = 16'h159a1;
    // 8'h71: midi_note_to_tone_freq = 16'h16e2f;
    // 8'h72: midi_note_to_tone_freq = 16'h183f5;
    // 8'h73: midi_note_to_tone_freq = 16'h19b07;
    // 8'h74: midi_note_to_tone_freq = 16'h1b378;
    // 8'h75: midi_note_to_tone_freq = 16'h1cd5c;
    // 8'h76: midi_note_to_tone_freq = 16'h1e8cc;
    // 8'h77: midi_note_to_tone_freq = 16'h205dc;
    // 8'h78: midi_note_to_tone_freq = 16'h224a8;
    // 8'h79: midi_note_to_tone_freq = 16'h24547;
    // 8'h7a: midi_note_to_tone_freq = 16'h267d8;
    // 8'h7b: midi_note_to_tone_freq = 16'h28c77;
    // 8'h7c: midi_note_to_tone_freq = 16'h2b343;
    // 8'h7d: midi_note_to_tone_freq = 16'h2dc5e;
    // 8'h7e: midi_note_to_tone_freq = 16'h307ea;
    // 8'h7f: midi_note_to_tone_freq = 16'h3360e;
  endcase

endfunction

`endif
