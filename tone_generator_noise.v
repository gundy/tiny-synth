// generate noise! :)
// out_data is 12-bit noise that is behaviourally similar to what the 6581
// SID chip did
module tone_generator_noise #(
  parameter OUTPUT_BITS = 12
)(
  input clk,
  input rst,
  output wire [OUTPUT_BITS-1:0] dout);

  reg [22:0] lsfr = 23'b01101110010010000101011;

  always @(posedge clk or posedge rst) begin
    if (rst)
      begin
        lsfr <= 23'b01101110010010000101011;
      end
    else
      begin
      // The noise output is taken from intermediate bits of a 23-bit shift register
      // Operation: Calculate EOR result, shift register, set bit 0 = result.
      //
      //                        ----------------------->---------------------
      //                        |                                            |
      //                   ----EOR----                                       |
      //                   |         |                                       |
      //                   2 2 2 1 1 1 1 1 1 1 1 1 1                         |
      // Register bits:    2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 <---
      //                   |   |       |     |   |       |     |   |
      // OSC3 bits  :      7   6       5     4   3       2     1   0
      //
      // Since waveform output is 12 bits the output is left-shifted 4 times.

      lsfr <= { lsfr[21:0], lsfr[22] ^ lsfr[17] };
    end
  end

  assign dout = { lsfr[22], lsfr[20], lsfr[16], lsfr[13], lsfr[11], lsfr[7], lsfr[4], lsfr[2], {(OUTPUT_BITS-8){1'b0}} };

endmodule
