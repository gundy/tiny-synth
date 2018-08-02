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
module envelope_generator #(
  parameter CLK_FREQ = 1000000,
  parameter ACCUMULATOR_BITS = 26
)
(
  input clk,
  input gate,
  input [3:0] a,
  input [3:0] d,
  input [3:0] s,
  input [3:0] r,
  output wire [7:0] amplitude,
  input rst);

  localparam  ACCUMULATOR_SIZE = 2**ACCUMULATOR_BITS;
  localparam  ACCUMULATOR_MAX  = ACCUMULATOR_SIZE-1;

  reg [ACCUMULATOR_BITS:0] accumulator;
  reg [16:0] accumulator_inc;  /* value to add to accumulator */


  // calculate the amount to add to the accumulator each clock cycle to
  // achieve a full-scale value in n number of seconds. (n can be fractional seconds)
  `define CALCULATE_PHASE_INCREMENT(n) $rtoi(ACCUMULATOR_SIZE / (n * CLK_FREQ))

  function [16:0] attack_table;
    input [3:0] param;
    begin
      case(param)
        4'b0000: attack_table = `CALCULATE_PHASE_INCREMENT(0.002);  // 33554
        4'b0001: attack_table = `CALCULATE_PHASE_INCREMENT(0.008);
        4'b0010: attack_table = `CALCULATE_PHASE_INCREMENT(0.016);
        4'b0011: attack_table = `CALCULATE_PHASE_INCREMENT(0.024);
        4'b0100: attack_table = `CALCULATE_PHASE_INCREMENT(0.038);
        4'b0101: attack_table = `CALCULATE_PHASE_INCREMENT(0.056);
        4'b0110: attack_table = `CALCULATE_PHASE_INCREMENT(0.068);
        4'b0111: attack_table = `CALCULATE_PHASE_INCREMENT(0.080);
        4'b1000: attack_table = `CALCULATE_PHASE_INCREMENT(0.100);
        4'b1001: attack_table = `CALCULATE_PHASE_INCREMENT(0.250);
        4'b1010: attack_table = `CALCULATE_PHASE_INCREMENT(0.500);
        4'b1011: attack_table = `CALCULATE_PHASE_INCREMENT(0.800);
        4'b1100: attack_table = `CALCULATE_PHASE_INCREMENT(1.000);
        4'b1101: attack_table = `CALCULATE_PHASE_INCREMENT(3.000);
        4'b1110: attack_table = `CALCULATE_PHASE_INCREMENT(5.000);
        4'b1111: attack_table = `CALCULATE_PHASE_INCREMENT(8.000);
        default: attack_table = 65535;
      endcase
    end
  endfunction

  function [16:0] decay_release_table;
    input [3:0] param;
    begin
      case(param)
        4'b0000: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.006);
        4'b0001: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.024);
        4'b0010: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.048);
        4'b0011: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.072);
        4'b0100: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.114);
        4'b0101: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.168);
        4'b0110: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.204);
        4'b0111: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.240);
        4'b1000: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.300);
        4'b1001: decay_release_table = `CALCULATE_PHASE_INCREMENT(0.750);
        4'b1010: decay_release_table = `CALCULATE_PHASE_INCREMENT(1.500);
        4'b1011: decay_release_table = `CALCULATE_PHASE_INCREMENT(2.400);
        4'b1100: decay_release_table = `CALCULATE_PHASE_INCREMENT(3.000);
        4'b1101: decay_release_table = `CALCULATE_PHASE_INCREMENT(9.000);
        4'b1110: decay_release_table = `CALCULATE_PHASE_INCREMENT(15.00);
        4'b1111: decay_release_table = `CALCULATE_PHASE_INCREMENT(24.00);
        default: decay_release_table = 65535;
      endcase
    end
  endfunction

  localparam OFF     = 3'd0;
  localparam ATTACK  = 3'd1;
  localparam DECAY   = 3'd2;
  localparam SUSTAIN = 3'd3;
  localparam RELEASE = 3'd4;

  reg[2:0] state = OFF;


  // value to add to accumulator during attack phase
  // calculated from lookup table below based on attack parameter
  reg [16:0] attack_inc;
  always @(a) begin
    attack_inc <= attack_table(a); // convert 4-bit value into phase increment amount
  end

  // value to add to accumulator during decay phase
  // calculated from lookup table below based on decay parameter
  reg [16:0] decay_inc;
  always @(d) begin
      decay_inc <= decay_release_table(d); // convert 4-bit value into phase increment amount
  end

  reg [7:0] sustain_volume;  // 4-bit volume expanded into an 8-bit value
  reg [7:0] sustain_gap;     // gap between sustain-volume and full-scale (255)
                             // used to calculate decay phase scale factor
  always @(s) begin
    sustain_volume <= { s, 4'b0000 };
    sustain_gap <= 255 - sustain_volume;
  end

  // value to add to accumulator during release phase
  reg [16:0] release_inc;
  always @(r) begin
      release_inc <= decay_release_table(r); // convert 4-bit value into phase increment amount
  end

  reg [16:0] dectmp;  /* scratch-register for intermediate result of decay scaling */
  reg [16:0] reltmp;  /* scratch-register for intermediate-result of release-scaling */


  reg [7:0] exp_out;  // exponential decay mapping of accumulator output; used for decay and release cycles
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

  always @(posedge clk)
    begin
      case (state)
        ATTACK:  accumulator_inc = attack_inc;
        DECAY:   accumulator_inc = decay_inc;
        RELEASE: accumulator_inc = release_inc;
        default: accumulator_inc = 0;
      endcase

      accumulator = accumulator + accumulator_inc;
      overflow = accumulator[ACCUMULATOR_BITS];
     case(state)
        ATTACK:
          begin  // ATTACK
            if (overflow)
              begin
                accumulator <= 0;
                state <= next_state(state, gate);
              end
            else
              begin
                amplitude <= accumulator[ACCUMULATOR_BITS-1 -: 8];
              end
          end
        DECAY:
            begin // DECAY
              if (overflow)
                begin
                  accumulator <= 0;
                  amplitude <= sustain_volume;
                  state <= next_state(state, gate);
                end
              else
                begin
                  dectmp <= ((exp_out * sustain_gap) >> 8) + sustain_volume;
                  amplitude = dectmp;
                end
            end
          SUSTAIN:
              begin // SUSTAIN
                amplitude <= sustain_volume;
                accumulator <= 0;
                state <= next_state(state, gate);
              end
          RELEASE:
              begin  // RELEASE
                  if (overflow)
                    begin
                      amplitude <= 0;
                      accumulator <= 0;
                      state <= next_state(state, gate);
                    end
                  else begin
                    reltmp <= ((exp_out * sustain_volume) >> 8);
                    amplitude <= reltmp;
                    if (gate)
                      begin
                      // re-gated during release phase, reset to attack
//                        amplitude <= 0;
                        state <= ATTACK;
                        accumulator <= 0;
                      end
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
endmodule
