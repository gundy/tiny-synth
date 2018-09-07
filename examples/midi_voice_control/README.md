# Description

A simple MIDI-based example for tiny-synth.

This example is a four-voice MIDI-connected synthesizer.

This example includes support for controlling MIDI parameters using
the general-purpose controllers that some MIDI keyboards have.

My keyboard is made by Roland, and has controller knobs which send messages of the format:

`Bc aa bb`

Where `c` is the channel number (usually 0), `aa` is the controller number (`0x0e` -> `0x15` for the 8 knobs I have available from left-to-right), and `bb` is a value from `0x00` -> `0x7f` which represents the value that has been set.

According to the notes [here](http://www.indiana.edu/~emusic/etext/MIDI/chapter3_MIDI6.shtml), that covers a range that includes the general purpose controllers (`0x10` -> `0x13`), and some "undefined" controllers.

I've chosen to map the values to knobs that work well for me, with my keyboard, but please feel free to check what messages your equipment sends, and adjust the mappings accordingly.

## Principle of operation

The MIDI interface uses Clifford Wolf's simpleuart code (slightly modified so that it could be used outside of the PicoSoC environment) to read data from the MIDI interface.  

`simpleuart` is wrapped with the `midi_uart` module, which essentially waits for whole MIDI frames (command+parameter messages) to arrive before passing them up to the next layer.

`midi_player` instantiates 8 voices, and keeps track which voices are available, and which are busy playing.  When a "note-on" MIDI message arrives, the first available voice is chosen, and the voice is assigned / gated appropriately. "note-off" messages simply find all voices playing the correct note, and gate them off.

# Before you start

This example requires a bit of extra circuitry - namely MIDI input requires a H11L1 opto-coupler to isolate your instrument, and to help prevent ground loops as per the MIDI specification.

## Audio output

As with the other tiny-synth examples, audio-out requires some analog circuitry:


The below circuit can be used to filter the output from `PIN_1`.

```      
       e.g. 330 ohm      eg. 10uF
  PIN_1 >---./\/\/\.---o------| |-------> Analog out >--
                       |
                      ---
                      --- eg. 0.1uF
                       |
                       |
                      --- GND
                       -                 
```

## MIDI input

MIDI input is via a 5-pin DIN MIDI connector (I used a breadboard-friendly one),
and an H11L1 opto-coupler, with a few passives.

The circuit I used is described below.

### MIDI connector pinout

The pins in the MIDI connector are numbered as below.  Imagine this is a female
DIN socket, and you're looking at it head-on.

```

5-PIN MIDI female socket; looking head-on

     - '|_|' -
   '           '
  | 1         3 |
   . 4       5  .
    .    2    .
      `-----'

```

### Circuit diagram

```                                                                           
                                                                         ___ GND
                                                                          |
                                                       H11L1             --- 1uF
                                              _____________________      ---
                         220ohm             1 |                   | 6     |
    MIDI_IN PIN4 -------./\/\.----o-----------|---.       ----.o--|-------o----------o-----------> 3v3
                                 _|_          |  _|_     |     .  | 4                \
                          1N4148 /_\          |  \ / ''  | \=\ |o-|----------.       / 270ohm
                                  |         2 |  ~~~     |     .  | 5        |       \
    MIDI_IN PIN5 -----------------o-----------|---'       ----'o--|----.     `-------o-----------> UART RX (PIN 14 on TinyFPGA BX)           
                                              |___________________|    |
                                                                      --- GND
```
