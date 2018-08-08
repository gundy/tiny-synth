/*
 * Tiny-synth example: triggering envelope generators from an external pin.
 *
 * This example will trigger a middle C major chord (C,E,G notes) and play it
 * from PIN 1 whenever PIN 13 is brought to ground.
 *
 * The example makes use of the ADSR envelope generator, which is programmed
 * to have a relatively fast attack time, approximately 50% sustain volume,
 * and a slow decay.
 *
 * It also demonstrates the principle of mixing multiple voices into a
 * single channel for output.
 *
 * You will need to make sure that PIN_1 has a low-pass filter and AC coupling
 * capacitor on the output as per README.md.
 */

`define __TINY_SYNTH_ROOT_FOLDER "../.."
`include "../../hdl/tiny-synth-all.vh"

// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    input PIN_13,  // gate
    output USBPU,  // USB pull-up resistor
    output PIN_1);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    wire [11:0] voice_data_c;
    wire [11:0] voice_data_e;
    wire [11:0] voice_data_g;

    reg trigger_in;
    SB_IO #(
        .PIN_TYPE(6'b0000_01),
        .PULLUP(1'b1)
    ) gate_trigger_io_conf (
      .PACKAGE_PIN(PIN_13),
      .D_IN_0(trigger_in)
    );

    wire ONE_MHZ_CLK; /* 1MHz clock for tone generator */
    clock_divider #(.DIVISOR(16)) mhzclkgen (.cin(CLK), .cout(ONE_MHZ_CLK));

    wire SAMPLE_CLK;
    clock_divider #(
      .DIVISOR((16000000/44100))
    ) sample_clk_divider(.cin(CLK), .cout(SAMPLE_CLK));

    // tone_freq is calculated by (16777216 * freq) / 1000000
    // so, for 261.63Hz (Middle C), tone_freq needs to be 4389.
    voice voice_c(
      .main_clk(ONE_MHZ_CLK), .sample_clk(SAMPLE_CLK), .tone_freq(16'd4389) /* C4, 261.63Hz */, .rst(1'b0),
      .en_ringmod(1'b0), .ringmod_source(1'b0),
      .en_sync(1'b0), .sync_source(1'b0),
      .waveform_enable(4'b0001), .pulse_width(12'd2047),
      .dout(voice_data_c),
      .attack(4'b0010), .decay(4'b0010), .sustain(4'b1000), .rel(4'b1100),
      .gate(!trigger_in)
    );

    voice voice_e(
      .main_clk(ONE_MHZ_CLK), .sample_clk(SAMPLE_CLK), .tone_freq(16'd5530) /* E4, 329.63Hz */, .rst(1'b0),
      .en_ringmod(1'b0), .ringmod_source(1'b0),
      .en_sync(1'b0), .sync_source(1'b0),
      .waveform_enable(4'b0001), .pulse_width(12'd2047),
      .dout(voice_data_e),
      .attack(4'b0010), .decay(4'b0010), .sustain(4'b1000), .rel(4'b1100),
      .gate(!trigger_in)
    );

    voice voice_g(
      .main_clk(ONE_MHZ_CLK), .sample_clk(SAMPLE_CLK), .tone_freq(16'd6577) /* G4, 392.00Hz */, .rst(1'b0),
      .en_ringmod(1'b0), .ringmod_source(1'b0),
      .en_sync(1'b0), .sync_source(1'b0),
      .waveform_enable(4'b0001), .pulse_width(12'd2047),
      .dout(voice_data_g),
      .attack(4'b0010), .decay(4'b0010), .sustain(4'b1000), .rel(4'b1100),
      .gate(!trigger_in)
    );

    wire [11:0] intermediate_mix;
    wire [11:0] final_mix;

    two_into_one_mixer intermediate_mixer(.a(voice_data_c), .b(voice_data_e), .dout(intermediate_mix));
    two_into_one_mixer final_mixer(.a(intermediate_mix), .b(voice_data_g), .dout(final_mix));

    pdm_dac #(.DATA_BITS(12)) dac1(
      .din(final_mix),
      .clk(main_clk),
      .dout(PIN_1)
    );

endmodule
