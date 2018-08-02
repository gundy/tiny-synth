// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    input PIN_13,  // gate
    output USBPU,  // USB pull-up resistor
    output PIN_1);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    wire [11:0] voice_data;

    reg trigger_in;
    SB_IO #(
        .PIN_TYPE(6'b0000_01),
        .PULLUP(1'b0)
    ) gate_trigger_io_conf (
      .PACKAGE_PIN(PIN_13),
      .D_IN_0(trigger_in)
    );

    wire ONE_MHZ_CLK; /* 1MHz clock for tone generator */
    clock_divider #(.DIVISOR(16)) mhzclkgen (.cin(CLK), .cout(ONE_MHZ_CLK));

    // wire SLOW_CLK;  /* slow clock (10Hz) used to trigger the gate on the voice */
    // clock_divider #(.DIVISOR(1600000)) slowclkgen (.cin(CLK), .cout(SLOW_CLK));

    voice voice1(
      .clk(ONE_MHZ_CLK), .tone_freq(16'd1097) /* C3 */, .rst(1'b0),
      .en_ringmod(1'b0), .ringmod_source(1'b0),
      .en_sync(1'b0), .sync_source(1'b0),
      .waveform_enable(4'b0010), .pulse_width(12'd2047),
      .dout(voice_data),
      .attack(4'b0011), .decay(4'b0100), .sustain(4'b1000), .rel(4'b1100),
      .gate(trigger_in)
      // .gate(SLOW_CLK)
      );

    pdm_dac #(.DATA_BITS(12)) dac1(
      .din(voice_data),
      .clk(CLK),
      .dout(PIN_1)
    );

endmodule
