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
`include "song_player.vh"

// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output USBPU,  // USB pull-up resistor
    output PIN_1);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    localparam MAIN_CLK_FREQ = 16000000;
    localparam BPM = 120;

    // TICK_HZ is the frequency in Hz that we are
    // going to tick through each row in a bar.

    // We want each step in a bar to represent an 1/8th note.

    // At 120bpm, we have 120 quarter-notes per minute.
    // This is two quarter-notes per second.

    // This means that we need to send ticks at four ticks
    // per second (twice as fast) so that each step represents
    // 1/8th note, or 8 ticks per second (four times as fast)
    // for 16th notes.

    // The bars in the demo song are arranged as 16th notes,
    // so to get the "step" frequency we multiply BPM by 4
    // and then divide by 60.

    // Finally, we multiply by eight, because the tick clock
    // actually gets divided by 8 in the player so that it
    // can perform sub-tick tasks (eg.
    // gating/ungating the envelope generator, and in future
    // performing effect processing).

    // We want to step through 1 bar in approximately 2 seconds.
    localparam TICK_HZ = ((BPM * 4) / 60) * 8;

    // amount we need to divide the main clock by to get our tick clock
    localparam TICK_DIVISOR = $rtoi(MAIN_CLK_FREQ / TICK_HZ);

    wire tick_clock;
    clock_divider #(.DIVISOR(TICK_DIVISOR)) tick_divider(.cin(CLK), .cout(tick_clock));

    wire ONE_MHZ_CLK;
    clock_divider #(.DIVISOR(16)) mhz_clk_divider(.cin(CLK), .cout(ONE_MHZ_CLK));

    localparam SAMPLE_BITS = 12;

    // divide main clock down to 44100Hz for sample output (note this clock will have
    // a bit of jitter because 44.1kHz doesn't go evenly into 16MHz).
    wire SAMPLE_CLK;
    clock_divider #(
      .DIVISOR((16000000/44100))
    ) sample_clk_divider(.cin(CLK), .cout(SAMPLE_CLK));

    signed wire[SAMPLE_BITS-1:0] final_mix;
    song_player #(.DATA_BITS(SAMPLE_BITS)) player(.main_clk(ONE_MHZ_CLK), .sample_clk(SAMPLE_CLK), .tick_clock(tick_clock), .audio_out(final_mix));

    pdm_dac #(.DATA_BITS(SAMPLE_BITS)) dac1(
      .din(final_mix),
      .clk(CLK),  // DAC runs at full 16MHz speed.
      .dout(PIN_1)
    );

endmodule
