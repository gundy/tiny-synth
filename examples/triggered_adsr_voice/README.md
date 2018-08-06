# Tiny-Synth Example : External gate for C Major Chord

## Description

This example will trigger a middle C major chord (C,E,G notes) and output the audio signal to `PIN_1`.  The notes will be triggered whenever `PIN_13` is brought to ground.

The example makes use of tiny-synth's `envelope_generator` module, which is programmed to have a relatively fast attack time, approximately 50% sustain volume, and a slow decay.

The code also demonstrates the principle of mixing three voices into a single channel using the `two_into_one_mixer` module for output, and using the `pdm_dac` module for generating an "analog" signal.

You will need to make sure that PIN_1 has a low-pass filter and AC coupling capacitor on the output as per README.md, and you will also need to have a way of momentarily bringing PIN 13 to ground (eg. a switch).

## Before you start

"Analog" output is produced by a pulse-density modulator.  This means that the output is actually a high-frequency square wave, and in order to see something resembling analog output, you'll need to use at least a simple low-pass RC filter on the output pin(s).

The below circuit works well enough for me, but YMMV.

```      
       e.g. 330 ohm      eg. 10uF
  PIN_1 >---./\/\/\.---o------| |-------> "Analog" output
                       |
                      ---
                      --- eg. 0.1uF
                       |
                       |
                      --- GND
                       -                 
```

You will also need to wire a switch between PIN 13 and ground.
This switch is used to "gate" the waveform.

```

    PIN 13 >----.
                |
                o
                 \    <-- SW1: trigger waveform
                  \  
                o
                |
              __|__
               ---
                -
```
