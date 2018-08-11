`ifndef __TINY_SYNTH_MIDI_NOTE_LOOKUP__
`define __TINY_SYNTH_MIDI_NOTE_LOOKUP__

/*********************************************************\
* MIDI note lookup
* --------------------------------------------------------
* - convert from MIDI note number (0-127; 60 = middle C)
*    to a { note:4, octave:4 } pair for use by tiny-synth.
\*********************************************************/
 module midi_note_lookup (
   input wire [6:0] midi_note,
   output wire [7:0] note_and_octave
 );

  reg [7:0] rom [0:127];

  initial
  begin
    $readmemh({`__TINY_SYNTH_ROOT_FOLDER , "/examples/midi/MIDI_note_to_note_and_octave.rom"}, rom);
  end

  assign note_and_octave = rom[midi_note];

endmodule

`endif
