# Tiny-Synth Example : External gate control of C Major chord

## Description

This example configures three triangle-wave tone generators, one for each of the notes C, E, and G.  Together these notes form a C-Major chord.

The chord is triggered whenever `PIN_13` is brought to ground.

The resulting audio signal is routed to `PIN_1`.  

The example makes use of tiny-synth's `envelope_generator` module, which is programmed to have a relatively fast attack time, approximately 50% sustain volume, and a slow decay.

The code also demonstrates the principle of mixing three voices into a single channel using the `two_into_one_mixer` module for output, and using the `pdm_dac` module for generating an "analog" signal.

You will need to make sure that `PIN_1` has a low-pass filter and AC coupling capacitor on the output as per README.md, and you will also need to have a way of momentarily bringing `PIN_13` to ground (eg. a switch).

## Before you start

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
