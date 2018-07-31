// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output USBPU,  // USB pull-up resistor
    output PIN_1);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    wire [11:0] voice_data;
    wire rst = 0;

    wire ONE_MHZ_CLK; /* 1MHz clock for tone generator */
    clock_divider #(.DIVISOR(16)) mhzclkgen (.cin(CLK), .cout(ONE_MHZ_CLK));

    wire SLOW_CLK;  /* slow clock (10Hz) used to trigger the gate on the voice */
    clock_divider #(.DIVISOR(1600000)) slowclkgen (.cin(CLK), .cout(SLOW_CLK));

    // triangle generator enabled @ 1kHz
    voice voice1(
      .clk(ONE_MHZ_CLK), .tone_freq(16'd16772), .rst(1'b0),
      .en_ringmod(1'b0), .ringmod_source(1'b0),
      .en_sync(1'b0), .sync_source(1'b0),
      .waveform_enable(4'b0001), .pulse_width(12'd0),
      .dout(voice_data),
      .attack(4'b0001), .decay(4'b0001), .sustain(4'b1000), .rel(4'b0010),
      .gate(SLOW_CLK)
      );

    pdm_dac #(.DATA_BITS(12)) dac1(
      .din(voice_data),
      .clk(CLK),
      .dout(PIN_1)
    );

endmodule
