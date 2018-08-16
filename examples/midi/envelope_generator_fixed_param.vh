`ifndef __TINY_SYNTH_ENV_GENERATOR_FIXED_PARAM__
`define __TINY_SYNTH_ENV_GENERATOR_FIXED_PARAM__

`include "../../hdl/eight_bit_exponential_decay_lookup.vh"

/* ===================
 * Envelope generator
 * ===================
 *
 * Creates an 8-bit ADSR (attack, decay, sustain, release) volume envelope.
 *
 *        ..
 *     A . `. D    S
 *      .    `----------
 *     .                . R
 *    .                  `  .
 *  ---------------------------->
 *                             t
 *
 * By modulating the tone generator output with an ADSR envelope like this,
 * it's possible to create many interesting sounds.
 *
 * The input parameters are described in README.md.
 *
 * Principle of operation:
 *
 * The envelope generator is a state machine that makes use of an accumulator for
 * generation of the output wave shape & timing.  For each of the A/D/R stages,
 * the state is advanced when the accumulator overflows.
 *
 * The envelope is 'triggered' by a gate signal, and as long as gate is held
 * high, the envelope won't transition past the sustain phase.  When gate is
 * released, the envelope will transition into the release phase.
 *
 * The decay and release phases use an exponential fall-off.
 */
module envelope_generator_fixed_param #(
  parameter SAMPLE_CLK_FREQ = 44100,
  parameter ACCUMULATOR_BITS = 26,
  parameter ATTACK_INC = 1000,
  parameter DECAY_INC = 1000,
  parameter [7:0] SUSTAIN_VOLUME = 8'd128,
  parameter RELEASE_INC = 1000
)
(
  input clk,
  input gate,
  output is_idle,
  output reg [7:0] amplitude,
  input rst);

  localparam  ACCUMULATOR_SIZE = 2**ACCUMULATOR_BITS;
  localparam  ACCUMULATOR_MAX  = ACCUMULATOR_SIZE-1;

  reg [ACCUMULATOR_BITS:0] accumulator;
  reg [16:0] accumulator_inc;  /* value to add to accumulator */

  // calculate the amount to add to the accumulator each clock cycle to
  // achieve a full-scale value in n number of seconds. (n can be fractional seconds)
  `define CALCULATE_PHASE_INCREMENT(n) $rtoi(ACCUMULATOR_SIZE / ($itor(n) * SAMPLE_CLK_FREQ))

  // localparam ATTACK_INC =  `CALCULATE_PHASE_INCREMENT(ATTACK_SECONDS);
  // localparam DECAY_INC =  `CALCULATE_PHASE_INCREMENT(DECAY_SECONDS);
  // localparam RELEASE_INC =  `CALCULATE_PHASE_INCREMENT(RELEASE_SECONDS);
  localparam [7:0] SUSTAIN_GAP = 255 - SUSTAIN_VOLUME;

  // Envelope states
  localparam OFF     = 3'd0;
  localparam ATTACK  = 3'd1;
  localparam DECAY   = 3'd2;
  localparam SUSTAIN = 3'd3;
  localparam RELEASE = 3'd4;

  reg[2:0] state;

  assign is_idle = (state == OFF);

  initial begin
    state = OFF;
    amplitude = 0;
    accumulator = 0;
  end

  reg [16:0] dectmp;  /* scratch-register for intermediate result of decay scaling */
  reg [16:0] reltmp;  /* scratch-register for intermediate-result of release-scaling */

  wire [7:0] exp_out;  // exponential decay mapping of accumulator output; used for decay and release cycles
  eight_bit_exponential_decay_lookup exp_lookup(.din(accumulator[ACCUMULATOR_BITS-1 -: 8]), .dout(exp_out));

  /* calculate the next state of the envelope generator based on
     the state that we've just moved past, and the gate signal */
  function [2:0] next_state;
    input [2:0] s;
    input g;
    begin
      case ({ s, g })
        { ATTACK,  1'b0 }: next_state = RELEASE;  /* attack, gate off => skip decay, sustain; go to release */
        { ATTACK,  1'b1 }: next_state = DECAY;    /* attack, gate still on => decay */
        { DECAY,   1'b0 }: next_state = RELEASE;  /* decay, gate off => skip sustain; go to release */
        { DECAY,   1'b1 }: next_state = SUSTAIN;  /* decay, gate still on => sustain */
        { SUSTAIN, 1'b0 }: next_state = RELEASE;  /* sustain, gate off => go to release */
        { SUSTAIN, 1'b1 }: next_state = SUSTAIN;  /* sustain, gate on => stay in sustain */
        { RELEASE, 1'b0 }: next_state = OFF;      /* release, gate off => end state */
        { RELEASE, 1'b1 }: next_state = ATTACK;   /* release, gate on => attack */
        { OFF,     1'b0 }: next_state = OFF;      /* end_state, gate off => stay in end state */
        { OFF,     1'b1 }: next_state = ATTACK;   /* end_state, gate on => attack */
        default: next_state = OFF;  /* default is end (off) state */
      endcase
    end
  endfunction

  wire overflow;
  assign overflow = accumulator[ACCUMULATOR_BITS];

  reg prev_gate;

  always @(posedge clk)
    begin

      /* check for gate low->high transitions (straight to attack phase)*/
      prev_gate <= gate;
      if (gate && !prev_gate)
        begin
          accumulator <= 0;
          state <= ATTACK;
        end

      /* otherwise, flow through ADSR state machine */
      if (overflow)
        begin
          accumulator <= 0;
          dectmp <= 8'd255;
          state <= next_state(state, gate);
        end
      else begin
        case (state)
          ATTACK:
            begin
              accumulator <= accumulator + ATTACK_INC;
              amplitude <= accumulator[ACCUMULATOR_BITS-1 -: 8];
            end
          DECAY:
            begin
              accumulator <= accumulator + DECAY_INC;
              dectmp <= ((exp_out * SUSTAIN_GAP) >> 8) + SUSTAIN_VOLUME;
              amplitude <= dectmp;
            end
          SUSTAIN:
          begin
            amplitude <= SUSTAIN_VOLUME;
            state <= next_state(state, gate);
          end
          RELEASE:
            begin
              accumulator <= accumulator + RELEASE_INC;
              reltmp <= ((exp_out * SUSTAIN_VOLUME) >> 8);
              amplitude <= reltmp;
              if (gate) begin
                amplitude <= 0;
                accumulator <= 0;
                state <= next_state(state, gate);
              end
            end
          default:
            begin
              amplitude <= 0;
              accumulator <= 0;
              state <= next_state(state, gate);
            end
        endcase
    end
  end
endmodule

`endif
