`ifndef __TINY_SYNTH_SONG_PLAYER__
`define __TINY_SYNTH_SONG_PLAYER__

`ifndef __TINY_SYNTH_ROOT_FOLDER
`define __TINY_SYNTH_ROOT_FOLDER ("../..")
`endif

`include "../../hdl/tiny-synth-all.vh"

`define NUM_ROWS_PER_BAR (16)
`define NUM_BARS (7)
`define NUM_CHANNELS (4)
`define NUM_PATTERNS (7)
`define SONG_LENGTH (25)

/********************************\
* BAR                            *
\********************************/
 module bar_rom (
   input wire [7:0] bar_idx,
   input wire [7:0] row_idx,
   output wire [7:0] note
 );

  reg [7:0] rom [0:`NUM_BARS-1][0:`NUM_ROWS_PER_BAR-1];

  initial
  begin
    $readmemh({`__TINY_SYNTH_ROOT_FOLDER , "/examples/song_player/example_song_bars.rom"}, rom);
  end

  assign note = rom[bar_idx][row_idx];

endmodule


/********************************\
* PATTERN                        *
\********************************/
 module pattern_rom (
   input wire [7:0] pat_idx,
   input wire [7:0] chan_idx,
   output wire [7:0] bar_idx
 );

  reg [7:0] rom [0:`NUM_PATTERNS-1][0:`NUM_CHANNELS-1];

  initial
  begin
    $readmemh({`__TINY_SYNTH_ROOT_FOLDER , "/examples/song_player/example_song_patterns.rom"}, rom);
  end

  assign bar_idx = rom[pat_idx][chan_idx];

endmodule


/********************************\
* SONG                           *
\********************************/
 module song_rom (
   input wire [7:0] song_pos,
   output wire [7:0] pattern_idx
 );

  reg [7:0] rom [0:`SONG_LENGTH-1];

  initial
  begin
    $readmemh({`__TINY_SYNTH_ROOT_FOLDER , "/examples/song_player/example_song_pattern_map.rom"}, rom);
  end

  assign pattern_idx = rom[song_pos];

endmodule

/*===============================================================================
 * main song player routine
 *==============================================================================*/

 module song_player (
   input wire main_clk,
   input wire tick_clock,
   output [11:0] audio_out
 );

   // convert a 4-bit note (1 = C, ..., 12 = B) into a value
   // that can be loaded into the phase accumulator of an instrument.
   function [15:0] note_to_freq(
     input [3:0] note
   );

     begin
       case (note)
         1:  note_to_freq = 17557; /* C 6 */
         2:  note_to_freq = 18601; /* C#6 */
         3:  note_to_freq = 19709; /* D 6 */
         4:  note_to_freq = 20897; /* D#6 */
         5:  note_to_freq = 22121; /* E 6 */
         6:  note_to_freq = 23436; /* F 6 */
         7:  note_to_freq = 24830; /* F#6 */
         8:  note_to_freq = 26306; /* G 6 */
         9:  note_to_freq = 27871; /* G#6 */
         10: note_to_freq = 29528; /* A 6 */
         11: note_to_freq = 31234; /* A#6 */
         12: note_to_freq = 33144; /* B 6 */
         default: note_to_freq = 0;
       endcase
     end
   endfunction

   /* Song position and bar position drive the note lookup for
      each channel that happens below */
   reg [7:0] song_position;
   reg [7:0] bar_position;
   reg [0:2] tick_timer;
   wire[11:0] channel_samples[0:3];

   initial
   begin
     song_position = 0;  /* index into song-rom */
     bar_position = 0;   /* index into currently playing bar */
     tick_timer = 0;     /* each timeslot is split into multiple 'ticks' */
   end

   wire[11:0] intermediate_mix[0:1];

   two_into_one_mixer mix1(.a(channel_samples[0]), .b(channel_samples[1]), .dout(intermediate_mix[0]));
   two_into_one_mixer mix2(.a(channel_samples[2]), .b(channel_samples[3]), .dout(intermediate_mix[1]));
   two_into_one_mixer final_mix(.a(intermediate_mix[0]), .b(intermediate_mix[1]), .dout(audio_out));

   // look up appropriate pattern based on song position
   wire[7:0] current_pattern_idx;
   song_rom song_rom(.song_pos(song_position), .pattern_idx(current_pattern_idx));

   // look up appropriate bar for each channel from pattern rom
   wire[7:0] current_bar_for_channel[0:3];
   pattern_rom ch0_pattern_rom(.chan_idx(8'd0), .bar_idx(current_bar_for_channel[0]), .pat_idx(current_pattern_idx));
   pattern_rom ch1_pattern_rom(.chan_idx(8'd1), .bar_idx(current_bar_for_channel[1]), .pat_idx(current_pattern_idx));
   pattern_rom ch2_pattern_rom(.chan_idx(8'd2), .bar_idx(current_bar_for_channel[2]), .pat_idx(current_pattern_idx));
   pattern_rom ch3_pattern_rom(.chan_idx(8'd3), .bar_idx(current_bar_for_channel[3]), .pat_idx(current_pattern_idx));

   // look up current "note" for each channel based on bar position
   wire[7:0] current_note_for_channel[0:3];
   bar_rom ch0_bar_rom(.bar_idx(current_bar_for_channel[0]),  .note(current_note_for_channel[0]), .row_idx(bar_position));
   bar_rom ch1_bar_rom(.bar_idx(current_bar_for_channel[1]),  .note(current_note_for_channel[1]), .row_idx(bar_position));
   bar_rom ch2_bar_rom(.bar_idx(current_bar_for_channel[2]),  .note(current_note_for_channel[2]), .row_idx(bar_position));
   bar_rom ch3_bar_rom(.bar_idx(current_bar_for_channel[3]),  .note(current_note_for_channel[3]), .row_idx(bar_position));

   // look up the appropriate frequency to play for each channel based on the note (map note -> octave 6 frequency, and then shift right by (6 - requested octave))
   wire[15:0] current_freq_for_channel[0:3];
   assign current_freq_for_channel[0] = note_to_freq(current_note_for_channel[0][7:4]) >> (6 - current_note_for_channel[0][3:0]);
   assign current_freq_for_channel[1] = note_to_freq(current_note_for_channel[1][7:4]) >> (6 - current_note_for_channel[1][3:0]);
   assign current_freq_for_channel[2] = note_to_freq(current_note_for_channel[2][7:4]) >> (6 - current_note_for_channel[2][3:0]);
   assign current_freq_for_channel[3] = note_to_freq(current_note_for_channel[3][7:4]) >> (6 - current_note_for_channel[3][3:0]);

   // registers used to drive instruments for each channel; these are output by
   // the song player tick_clock handler
   reg[15:0] instrument_frequency[0:3];
   reg instrument_gate[0:3];


   // instrument definitions
   // voice 1/channel 1 = bass-riff
   wire[11:0] saw_out;
   voice channel1_instrument(
     .clk(main_clk), .tone_freq(instrument_frequency[0]), .rst(1'b0),
     .en_ringmod(1'b0), .ringmod_source(1'b0),
     .en_sync(1'b0), .sync_source(1'b0),
     .waveform_enable(4'b0010), .pulse_width(12'd2047),
     .dout(channel_samples[0]),
     .attack(4'b0100), .decay(4'b0010), .sustain(4'b0110), .rel(4'b1100),
     .gate(instrument_gate[0])
   );


   wire[11:0] kd_samples1;
   wire[11:0] kd_samples2;

   /* kick drum
    *
    * kick drum is made up of two voices; one playing a random noise output
    * for a short period of time, and another that plays a relatively low
    * frequency "thud".
    */
   // voice 2 = kick drum
   voice channel2_instrument(
     .clk(main_clk), .tone_freq(instrument_frequency[1]), .rst(1'b0),
     .en_ringmod(1'b0), .ringmod_source(1'b0),
     .en_sync(1'b0), .sync_source(1'b0),
     .waveform_enable(4'b0001), .pulse_width(12'd1000),
     .dout(kd_samples1),
     .attack(4'b0001), .decay(4'b0010), .sustain(4'b1111), .rel(4'b0010),
     .gate(instrument_gate[1])
   );
   // voice 2, part 2 = kick drum part 2 (noise oscillator)
   voice channel2b_instrument(
     .clk(main_clk), .tone_freq(16'd18000), .rst(1'b0),
     .en_ringmod(1'b0), .ringmod_source(1'b0),
     .en_sync(1'b0), .sync_source(1'b0),
     .waveform_enable(4'b1000), .pulse_width(12'd1000),
     .dout(kd_samples2),
     .attack(4'b0000), .decay(4'b0000), .sustain(4'b1100), .rel(4'b0000),
     .gate(instrument_gate[1])
   );
   two_into_one_mixer kd_mix(.a(kd_samples1), .b(kd_samples2), .dout(channel_samples[1]));

   // voice 3 = open high hat
   voice channel3_instrument(
     .clk(main_clk), .tone_freq(instrument_frequency[2]), .rst(1'b0),
     .en_ringmod(1'b0), .ringmod_source(1'b0),
     .en_sync(1'b0), .sync_source(1'b0),
     .waveform_enable(4'b1000), .pulse_width(12'd400),
     .dout(channel_samples[2]),
     .attack(4'b0011), .decay(4'b0001), .sustain(4'b1000), .rel(4'b1000),
     .gate(instrument_gate[2])
   );

   // voice 4 = "snare" :)
   voice channel4_instrument(
     .clk(main_clk), .tone_freq(instrument_frequency[3]), .rst(1'b0),
     .en_ringmod(1'b0), .ringmod_source(1'b0),
     .en_sync(1'b0), .sync_source(1'b0),
     .waveform_enable(4'b1100), .pulse_width(12'd400),
     .dout(channel_samples[3]),
     .attack(4'b0010), .decay(4'b0010), .sustain(4'b1111), .rel(4'b1000),
     .gate(instrument_gate[3])
   );

   // used in tick handler for() loops
   integer ch=0;

   // song player tick clock handler
   always @(posedge tick_clock) begin
     if (tick_timer == 0) begin
       // play note
       for (ch = 0; ch <= 3; ch++) begin
         if (current_freq_for_channel[ch] != 0) begin
           instrument_frequency[ch] = current_freq_for_channel[ch];
           instrument_gate[ch] = 1;
         end // end if
       end // end for

       // increment bar and song counters
       bar_position = bar_position + 1;
       if (bar_position >= `NUM_ROWS_PER_BAR) begin
         bar_position = 0;
         song_position = song_position + 1;
         if (song_position >= `SONG_LENGTH) begin
           song_position = 0;
         end
       end
     end else begin /* tick_timer != 0 */
       for (ch = 0; ch <= 3; ch++) begin
         instrument_gate[ch] = 0; // turn off trigger
       end
     end

     tick_timer = tick_timer + 1;
   end // end always @posedge tick_clock


 endmodule

`endif
