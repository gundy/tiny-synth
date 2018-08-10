`ifndef __TINY_SYNTH_ALL__
`define __TINY_SYNTH_ALL__

`ifndef __TINY_SYNTH_ROOT_FOLDER
`define __TINY_SYNTH_ROOT_FOLDER ("..")
`endif

`include "clock_divider.vh"
`include "amplitude_modulator.vh"
`include "eight_bit_exponential_decay_lookup.vh"
`include "envelope_generator.vh"
`include "pdm_dac.vh"
`include "tone_generator_noise.vh"
`include "tone_generator_pulse.vh"
`include "tone_generator_saw.vh"
`include "tone_generator_triangle.vh"
`include "tone_generator.vh"
`include "two_into_one_mixer.vh"
`include "voice.vh"
`include "flanger.vh"
`include "filter_ewma.vh"

`endif
