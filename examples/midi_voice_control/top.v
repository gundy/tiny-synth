/*
 * Tiny-synth example: playing notes based on MIDI input
 */

`define __TINY_SYNTH_ROOT_FOLDER "../.."
`include "../../hdl/tiny-synth-all.vh"
`include "midi_player.vh"

// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
`ifdef blackice
    input CLK_100,    // 100MHz clock
`else
    input CLK,    // 16MHz clock
`endif
    output USBPU,  // USB pull-up resistor
    input PIN_22,  // serial (MIDI) data in
    output PIN_24, // serial (MIDI) data out
    output PIN_1,   /* audio out left */
    output PIN_2);  /* audio out right */

`ifdef blackice
    wire CLK;
    pll pll0 (.clock_in(CLK_100), .clock_out(CLK));
`endif

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    wire serial_rx;
    SB_IO #(
        .PIN_TYPE(6'b0000_01),
        .PULLUP(1'b0)
    ) serial_rx_pin_conf (
      .PACKAGE_PIN(PIN_22),
      .D_IN_0(serial_rx)
    );

    localparam SAMPLE_BITS = 12;

    wire signed [SAMPLE_BITS-1:0] final_mix;
    midi_player #(.SAMPLE_BITS(SAMPLE_BITS)) midi_player(.clk(CLK), .serial_rx(serial_rx), .serial_tx(PIN_24), .audio_data(final_mix));

    pdm_dac #(.DATA_BITS(SAMPLE_BITS)) dac_left(
      .din(final_mix),
      .clk(CLK),  // DAC runs at full 16MHz speed.
      .dout(PIN_1)
    );
    pdm_dac #(.DATA_BITS(SAMPLE_BITS)) dac_right(
      .din(final_mix),
      .clk(CLK),  // DAC runs at full 16MHz speed.
      .dout(PIN_2)
    );

endmodule
