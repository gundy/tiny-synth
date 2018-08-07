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

`include "song_player.vh"

// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    input PIN_13,  // gate
    output USBPU,  // USB pull-up resistor
    output PIN_1);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    localparam MAIN_CLK_FREQ = 16000000;
    localparam BPM = 120;            // 0.5s per quarter note = 2Hz
    localparam TIME_SIG_TOP = 16;
    localparam TIME_SIG_BOTTOM = 16;
    localparam TICKS_PER_BEAT = 8;

    // Frequency in Hz that we need to tick through each row
    // in a bar.
    localparam TICK_HZ = ((BPM * 2) / 60) * TIME_SIG_BOTTOM;

    // amount we need to divide the main clock by to get our tick clock
    localparam TICK_DIVISOR = $rtoi(MAIN_CLK_FREQ / TICK_HZ);

    wire tick_clock;
    clock_divider #(.DIVISOR(TICK_DIVISOR)) tick_divider(.cin(CLK), .cout(tick_clock));

    wire ONE_MHZ_CLK;
    clock_divider #(.DIVISOR(16)) mhz_clk_divider(.cin(CLK), .cout(ONE_MHZ_CLK));

    wire[11:0] final_mix;
    song_player player(.main_clk(ONE_MHZ_CLK), .tick_clock(tick_clock), .audio_out(final_mix));

    pdm_dac #(.DATA_BITS(12)) dac1(
      .din(final_mix),
      .clk(CLK),
      .dout(PIN_1)
    );

endmodule
