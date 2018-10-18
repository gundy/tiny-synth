# Overview

Tiny-synth is a an audio "synth" module written in verilog, for synthesis on an FPGA device such as the Lattice ICE40 series devices.  

Actually, it's a little more than just a synth - it's a set of building blocks for creating FPGA-based synth modules that you can choose to assemble in whichever way you choose.

It's called tiny-synth because it's reasonably small and simple - at least it started out that way - but also because it's been developed on a TinyFPGA BX board, which is genuinely quite tiny!

The synth in the top level verilog file (`top.v`) is loosely (okay, maybe not so loosely) based on the legendary MOS 6581 (SID) chip that provided audio to the Commodore 64.  It was something I thought I'd try to replicate as an introductory project for a [TinyFPGA](http://tinyfpga.com) [BX](https://tinyfpga.com/bx/guide.html) board that I'd purchased.

The demo project instantiates a module called a "`voice`"; The concept of a `voice` should be familiar to anyone who has looked at the SID chip. Each `voice` is made up of:

- a tone generator (capable of generating saw, triangle, square/pulse and noise waveforms).
- an ADSR envelope generator.
- an amplitude modulator that modulates the amplitude of the tone with the envelope generator's output.

"Analog" output is produced by a pulse-density modulator.  This means that the output is actually a high-frequency square wave, and in order to see anything resembling analog output, you'll need to use at least a simple low-pass RC filter on the output pin(s).

The below circuit works well enough for me, but YMMV.

```      
       e.g. 470 ohm      eg. 10uF
  DOUT   ---./\/\/\.---o------| |-------> "Analog" output
                       |
                      ---
                      --- eg. 0.1uF
                       |
                       |
                      --- GND
                       -                 
```

_Note: the resistor value above was originally specified as 330ohm, but it seems like this may have been putting the 8mA rated IO's on the FPGA at risk. Especially if you happened to accidentally short-circuit the output. The new recommendation is 470ohm._

The module has been synthesized and bench-tested on a TinyFPGA BX board using the [IceStorm](http://www.clifford.at/icestorm/) toolchain.

If you've got any problems or questions, please raise an issue against the project.

If you'd like to contribute to the project, pull requests are welcomed!  I'd especially love to see additional waveforms and something like a state-variable filter that can be wired into the audio path!  

If you use tiny-synth somewhere, or find this in any way useful please star the project and get in touch!

## Basic usage : TL;DR

To get started quickly, all that you really need to do is instantiate a ```voice``` module, and wire it up to a ```pdm_dac``` module.  Note the parameters below are constants, but you'll probably want a way of controlling/varying them for any kind of non-trivial use cases.

```verilog

    reg [11:0] voice_data;

    // instantiate a synthesizer voice
    voice voice(
      .clk(ONE_MHZ_CLK),
      .tone_freq(16'd16721),      /* (16777216/16721) * 1000000Hz = 1kHz tone */
      .waveform_enable(4'b0001),  /* triangle tone generator */
      .pulse_width(12'd0),        /* pulse width only used for pulse waveform */
      .rst(1'b0),                 /* force ReSeT pin low */
      .en_ringmod(1'b0),          /* disable ringmod */
      .ringmod_source(1'b0),      /* (source connection for ringmod; forced to zero) */
      .en_sync(1'b0),             /* disable oscillator synchronization */
      .sync_source(1'b0),         /* (source connection for sync; forced to zero) */
      .gate(SLOW_CLK),            /* gate on triggers attack; gate off triggers decay */
      .attack(4'b0001),           /* attack rate (8ms) */
      .decay(4'b0001),            /* decay rate (6ms)*/
      .sustain(4'b1000),          /* sustain level (~1/2 volume)*/
      .rel(4'b0010)               /* release rate (48ms) */
      .dout(voice_data),          /* route output to voice_data register */
    );

    // instantiate a DAC to take voice output and route it to an external pin with PDM modulation
    pdm_dac #(.DATA_BITS(12)) dac(
      .din(voice_data),
      .clk(CLK),   // DAC clock
      .dout(PIN_1) // route audio to PIN 1
    );
```

## Examples

The `/examples` folder contains a number of examples which give ideas for composing the various elements in tiny-synth into higher-level abstractions.

# Modules

## `voice`

### Overview

Each voice has a 24-bit phase-accumulator which is used to generate the output
waveforms.

It also has an ADSR envelope generator.

The envelope generator uses a linear attack, and an exponential fall-off function for the
decay and release cycles.

### Parameters

| parameter | default | description |
| --- | --- | --- |
| OUTPUT_BITS | 12 | bit-width of PCM output register |
| FREQ_BITS | 16 | number of bits to use for `tone_freq` input |
| PULSEWIDTH_BITS | 12 | number of bits resolution for `pulse_width` register |
| ACCUMULATOR_BITS | 24 | number of bits resolution for frequency accumulator |


### IO

| parameter | description |
| --- | --- |
| `clk:1` | reference clock for the tone generator |
| `tone_freq:16` | Value to add to the phase-accumulator every `clk` cycle.  When the accumulator overflows, the next output cycle starts. <br><br>`Fout (Hz)` = (`tone_freq` x `clk`) / 16777216 <br><br>`tone_freq` = (`Fout (Hz)` x 16777216) / `clk` |
| `waveform_enable:4` | `0001` = triangle /\\/\\/\\ <br>`0010` = saw /&#124;/&#124;/&#124;<br>`0100` = pulse  _-_-_-_<br>`1000` = LFSR noise (random).  <br><br>If multiple waveforms are selected, the outputs are logically ANDed together. |
| `pulse_width:12` | when pulse waveform is selected, if accumulator < `pulse_width`, output is high; else low |
| `rst:1` | reset; when high, the accumulator is reset; as is the ADSR envelope generator. |
| `en_ringmod:1` | enable the ring modulator (only has any effect when the triangle wave is selected) |
| `ringmod_source:1` | source of modulation; should be the MSB from another voice's accumulator; this triggers the inversion of this voice's triangle waveform (as opposed to using it's own MSB). |
| `accumulator_msb:1` | most significant bit of accumulator - used to feed ringmod source of another oscillator. |
| `accumulator_overflow:1` | true when the value in this accumulator has wrapped past zero; used to sync with another oscillator. |
| `en_sync:1` | enable synchronizing this oscillator with sync_source. if true, this oscillator will reset to 0 whenever sync_source is set. |
| `sync_source:1` | when this is set to one, the oscillator's accumulator will be reset to 0. Normally fed from another oscillator to enable sync effects. |
| `gate` | A rising gate will trigger the ADSR cycle to begin, according to the timings in the `attack`/`decay`/`sustain`/`release` parameters. A falling gate will trigger the release cycle. |
| `attack:4` | How long it takes the envelope generator attack cycle to go from zero volume to full-scale. <br><br>`0000` = 2ms<br>`0001` = 8ms<br>`0010` = 16ms<br>`0011` = 24ms<br>`0100` = 38ms<br>`0101` = 56ms<br>`0110` = 68ms<br>`0111` = 80ms<br>`1000` = 100ms<br>`1001` = 250ms<br>`1010` = 500ms<br>`1011` = 800ms<br>`1100` = 1 second<br>`1101` = 3 seconds<br>`1110` = 5 seconds<br>`1111` = 8 seconds|
| `decay:4` | How long it takes the envelope generator to decay from full-scale after attack to the sustain level. <br><br>`0000` = 6ms<br>`0001` = 24ms<br>`0010` = 48ms<br>`0011` = 72ms<br>`0100` = 114ms<br>`0101` = 168ms<br>`0110` = 204ms<br>`0111` = 240ms<br>`1000` = 300ms<br>`1001` = 750ms<br>`1010` = 1.5 seconds<br>`1011` = 2.4 seconds<br>`1100` = 3 seconds<br>`1101` = 9 seconds<br>`1110` = 15 seconds<br>`1111` = 24 seconds|
| `sustain:4` | The level that the note will be sustained at while the 'gate' is still enabled. Values range from zero (off; ie. note will decay to zero without a sustain phase) to 15 (max). |
| `rel:4` | How long it takes the envelope generator to fall from the sustain level to zero once the gate has been switched off. <br><br>`0000` = 6ms<br>`0001` = 24ms<br>`0010` = 48ms<br>`0011` = 72ms<br>`0100` = 114ms<br>`0101` = 168ms<br>`0110` = 204ms<br>`0111` = 240ms<br>`1000` = 300ms<br>`1001` = 750ms<br>`1010` = 1.5 seconds<br>`1011` = 2.4 seconds<br>`1100` = 3 seconds<br>`1101` = 9 seconds<br>`1110` = 15 seconds<br>`1111` = 24 seconds |
| `dout:12` | digital sample output; a new sample is generated every CLK cycle. |

## pdm_dac

| parameter | description |
| --- | --- |
| `din:12` | Input data samples |
| `clk:1` | High speed clock for output |
| `dout:1` | Pulse-density modulated output |
