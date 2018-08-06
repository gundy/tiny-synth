# Tiny-Synth Example : Playing a song

## Description

This example plays a simple polyphonic song on `PIN_1` using a number of the tiny-synth components.

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

The two main inputs of interest are tone_frequency and trigger. You can set an instrument to play a particular note, and then trigger it. Easy.

### Bars

A bar represents a [musical bar](https://en.wikipedia.org/wiki/Bar_(music)), in other words a set of notes that will be played one after the other.

Unlike a musical bar however, bars here are not polyphonic.  You can only trigger one instrument in each time slot (row).

An example couple of bars might look like:

| Row # | Note | Octave |
| --- | ---: | --- |
|0 | `C`  | `2` |
|1 | `C`  | `2` |
|2 | `D`  | `2` |
|3 | `C`  | `2` |

| Row # | Note | Octave |
| --- | ---: | --- |
|0 | `D#` | `2` |
|1 | `C`  | `2` |
|2 | `F`  | `2` |
|3 | `D#` | `2` |

In the bars above, assuming we're playing in 4/4 time, each time slot represents a quarter note.

If you're able to, try playing the above bars slowly on an instrument and see what they sound like.

These bars could equally have been written with gaps every second row - ie. in 8/8 time:

| Row # | Note | Octave |
| --- | ---: | --- |
|0 | `C`  | `2` |
|1 | - | - |
|2 | `C`  | `2` |
|3 | - | - |
|4 | `D`  | `2` |
|5 | - | - |
|6 | `C`  | `2` |
|7 | - | - |

The effect is the same, but each slot now represents an eighth note.  Assuming that our player plays this bar at twice the rate of our first example, it will sound exactly the same, but if we wanted to we could insert extra notes in-between the ones that we played before.

If you're familiar with "tracker" software from the 90's, this is probably starting to seem quite familiar.

### Patterns

Patterns combine a number of rows together; each row being assigned to a particular channel.  This is where polyphony is introduced.

#### Example pattern:

`Pattern 0:`

| Channel # | 0 | 1 | 2 | 3 |
| --- | --- | --- | --- |
| *Bar #* | 1 | 2 | 3 | 7 |

Channels are mapped globally to particular instruments, so in the example above, channel 0 might be a bass instrument, 1 and 2 might be assigned to a piano, and 3 might be for percussion.

### Songs

You might have guessed already, but a song is simply:

* Details about the time signature and tempo to use
* A mapping of channels to instruments
* An ordered list of patterns to play

### Bringing it all together

So,

Song > Pattern > Bar and Instrument - that's all there is to it.
