# Tiny-Synth Example : Playing a song

## Description

This example plays a simple polyphonic song on `PIN_1` using a number of the tiny-synth components.

## Important Note

This demo, probably largely due to a lack of mechanical sympathy on my part,  is very close
to using all of the logic resources of the TinyFPGA BX.  `arachne-pnr` took almost 30 minutes
on my machine to place and route.

I've found if I turn off some of the effects like the flanger, things run a lot more quickly.

An opportunity for future enhancement might be to combine the percussion instruments into a single multplexed voice.

## Before you start

The below circuit (or similar) should be used to filter the output from `PIN_1` before connecting your FPGA to any audio equipment.

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

## Principle of operation

The song player is easiest to understand if we break it into sections.

### Instruments

Instruments present a simple interface:

```verilog
module instrument(
  input clk,
  input wire[16:0] tone_frequency,
  input wire gate,
  output wire [11:0] audio_data;
)
```

The two main inputs of interest for the instruments from the point of view of the
song player are `tone_frequency` and `gate`.
`tone_frequency` is used to choose the note that's being played, and `gate` is used
to trigger the instrument.

For the demo song I've created a number of instruments.  

* A "bass", which is a pulse tone that is passed through an exponentially weighted low-pass filter to smooth off some of the shrillness.
* An "open hi-hat" - a random oscillator with a relatively slow decay envelope
* A "snare" - another random oscillator with a relatively faster decay, at a lower frequency than the hi-hat.
* A "kick drum" - two voices - one is a short, sharp burst of noise; the other is a triangle wave for the "thump".

The output from all of these instruments is aggregated and collectively passed through a 1.2Hz flanger to give the sound a "richer" timbre.

### Bars and rows

A bar represents a [musical bar](https://en.wikipedia.org/wiki/Bar_(music)), in other words a set of notes that will be played one after the other.

Unlike a musical bar however, bars in this song player are not polyphonic.  We're only able to trigger one instrument in each row.

An example bar might look like this:

| Row # | Note | Octave |
| --- | ---: | --- |
|0 | `C`  | `2` |
|1 | `C`  | `2` |
|2 | `D`  | `2` |
|3 | `C`  | `2` |
|4 | `D#` | `2` |
|5 | `C`  | `2` |
|6 | `F`  | `2` |
|7 | `D#` | `2` |

In the bars above, assuming we're playing in 4/4 time, each time slot represents an eighth note.

These bars could equally have been written with gaps every second row - ie. each time step representing 1/16th note:

| Row # | Note | Octave |
| --- | ---: | --- |
|0 | `C`  | `2` |
|1 | - | - |
|2 | `C`  | `2` |
|3 | - | - |
|4 | `D`  | `2` |
|5 | - | - |
|6 | `C`  | `2` |
|... | ... | ... |
|... | ... | ... |
|E | `D#` | `2` |
|F | - | - |

The effect is the same, but each slot now represents an sixteenth note.  Assuming that our player plays this bar at twice the rate of our first example, it will sound exactly the same, but if we wanted to we could now insert extra notes in-between the ones that we played before.

By choosing a bar length that fits with the musical motifs that you're using, you can make composition easier, and also allow the song to compress into a smaller amount of space.

If you're familiar with "tracker" software from the 90's, this is probably starting to seem quite familiar.

Bars in the demo-song are stored in the `example_song_bars.rom` file, which also contains a few hints about how the encoding works.  Each note is stored as an 8-bit value. The high nibble is the note (`C`=`0x1`,`C#`=`0x2`,...,`B`=`0xC`), and the low nibble is the octave (0..6).  A value of `00` means that the note will be skipped.

### Ticks

You may notice a reference to the tick counter in the code if you go digging.

What I neglected to mention about Bars and Rows above is that each row is actually split into 8 "ticks".
The reason for this is to allow for sub-row processing such as instrument gating and effect processing.

As it stands now, instruments are gated on for one "tick", and then gated off.  A potential future enhancement might be to change the bar structure so that each row could also provide "gate on length".

### Patterns

Patterns combine a number of rows together; each row being assigned to a particular channel.  This is where polyphony is introduced.

#### Example pattern:

| Channel # | 0 | 1 | 2 | 3 |
| --- | --- | --- | --- |
| *Bar #* | 1 | 2 | 0 | 0 |

The above pattern can be interpreted as "Play Bar 1 on channel 0, Bar 2 on Channel 1, and Bar 0 on Channels 2 and 3".

Channels are mapped globally to particular instruments, so in the example above, channel 0 might be a bass instrument, 1 might be assigned to a piano, and 2/3 might be for percussion.

Patterns in the demo song are stored in the `example_song_patterns.rom` file.

### Songs

You might have guessed already, but a song is really only:

* Details about the time signature and tempo to use
* A mapping of channels to instruments
* An ordered list of patterns to play

The ordered list of patterns to play for the demo song is stored in the `example_song_pattern_map.rom` file.

### Homework

Try playing with the code. Change the bar and pattern rom files and see
what effect this has.  If you change the song length or number of bars you'll also need to update
the constants in the song_player.vh file.

Try changing the instrument definitions for each channel in the song_player.vh file.

Have fun!
