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
  output reg [7:0] amplitude,
  input rst);

  localparam  ACCUMULATOR_SIZE = 2**ACCUMULATOR_BITS;
  localparam  ACCUMULATOR_MAX  = ACCUMULATOR_SIZE-1;

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

  reg[2:0] state = 4;


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

  reg [ACCUMULATOR_BITS:0] accumulator;
  reg [16:0] accumulator_inc;  /* value to add to accumulator */

  reg [7:0] exp_out;  // exponential decay mapping of accumulator output; used for decay and release cycles
  eight_bit_exponential_decay_lookup exp_lookup(.din(accumulator[ACCUMULATOR_BITS-1 -: 8]), .dout(exp_out));

  always @(state)
  begin
    case(state)
      3'd0: accumulator_inc <= attack_inc;
      3'd1: accumulator_inc <= decay_inc;
      3'd2: accumulator_inc <= 0;
      3'd3: accumulator_inc <= release_inc;
      3'd4: accumulator_inc <= 0;
    endcase
  end

  function [2:0] next_state;
    input [2:0] s;
    input g;
    begin
      case ({ s, g })
        4'b0000: next_state = 3'b011;  /* attack, gate off => skip decay, sustain; go to release */
        4'b0001: next_state = 3'b001;  /* attack, gate still on => decay */
        4'b0010: next_state = 3'b011;  /* decay, gate off => skip sustain; go to release */
        4'b0011: next_state = 3'b010;  /* decay, gate still on => sustain */
        4'b0100: next_state = 3'b011;  /* sustain, gate off => go to release */
        4'b0101: next_state = 3'b010;  /* sustain, gate on => stay in sustain */
        4'b0110: next_state = 3'b100;  /* release, gate off => end state */
        4'b0111: next_state = 3'b001;  /* release, gate on => attack */
        4'b1000: next_state = 3'b100;  /* end_state, gate off => stay in end state */
        4'b1001: next_state = 3'b000;  /* end_state, gate on => attack */
        default: next_state = 3'b100;  /* default is end (off) state */
      endcase
    end
  endfunction

  always @(posedge clk)
    begin
      accumulator = accumulator + accumulator_inc;
      case(state)
        3'd0:
          begin  // ATTACK
            if (accumulator > ACCUMULATOR_MAX)
              begin
                accumulator <= 0;
                state <= next_state(state, gate);
              end
            else
              begin
                amplitude <= accumulator[ACCUMULATOR_BITS-1 -: 8];
              end
          end
        3'd1:
            begin // DECAY
              if (accumulator > ACCUMULATOR_MAX)
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
          3'd2:
              begin // SUSTAIN
                amplitude <= sustain_volume;
                accumulator <= 0;
                state <= next_state(state, gate);
              end
          3'd3:
              begin  // RELEASE
                if (gate) begin // re-gated during release phase, reset to attack
                    amplitude <= 0;
                    state <= 3'd0;
                    accumulator <= 0;
                  end
                else
                  begin
                  if (accumulator >= ACCUMULATOR_MAX)
                    begin
                      amplitude <= 0;
                      accumulator <= 0;
                      state <= next_state(state, gate);
                    end
                  else
                    begin
                      reltmp <= ((exp_out * sustain_volume) >> 8);
                      amplitude = reltmp;
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
