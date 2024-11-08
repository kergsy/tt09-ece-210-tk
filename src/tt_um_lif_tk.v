/*
 * Copyright (c) 2024 Taylor Kergan
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_lif_tk (
  input  wire [7:0] ui_in,    // Inputs [2:0] pattern_select, [7:3] base_current
  input  wire [7:0] uio_in,   // IOs: Coupling strength
  output wire [7:0] uo_out,   // Outputs: Spikes
  output wire [7:0] uio_out,  // IOs: First neuron state
  output wire [7:0] uio_oe,   // IOs: Enable path
  input  wire       ena,      
  input  wire       clk,      
  input  wire       rst_n     
);

  // Pattern selection from input
  wire [2:0] pattern_select = ui_in[2:0];
  wire [4:0] base_current_scale = ui_in[7:3];
  
  // Use uio_in directly for coupling strength
  wire [7:0] coupling_strength = uio_in;
  
  // Pattern-specific parameters
  reg [7:0] external_input;

  // Pattern parameter selection
  always @(*) begin
      case (pattern_select)
          3'b000: begin // Independent firing
              external_input = {base_current_scale, 3'b000};
          end
          3'b001: begin // Wave propagation
              external_input = {base_current_scale, 3'b000};
          end
          3'b010: begin // Synchronous firing
              external_input = {base_current_scale, 3'b000};
          end
          3'b011: begin // Clustered firing
              external_input = {base_current_scale, 3'b000};
          end
          3'b100: begin // Burst mode
              external_input = {base_current_scale, 3'b000};
          end
          default: begin
              external_input = {base_current_scale, 3'b000};
          end
      endcase
  end

  // Internal signals
  wire [7:0] spikes;
  wire [7:0] states [7:0];
  wire [7:0] coupling_currents [7:0];

  // Calculate coupling currents based on pattern
  genvar j;
  generate
      for (j = 0; j < 8; j = j + 1) begin : coupling_calc
          reg [7:0] curr;
          always @(*) begin
              case (pattern_select)
                  3'b001: // Wave
                      curr = spikes[(j-1+8) % 8] ? coupling_strength : 8'd0;
                  3'b010: // Synchronous
                      curr = (|spikes) ? coupling_strength : 8'd0;
                  3'b011: // Clustered
                      curr = spikes[(j+4) % 8] ? coupling_strength : 8'd0;
                  3'b100: // Burst
                      curr = (spikes[(j-1+8) % 8] || spikes[(j+1) % 8]) ? 
                             coupling_strength : 8'd0;
                  default:
                      curr = 8'd0;
              endcase
          end
          assign coupling_currents[j] = curr;
      end
  endgenerate

  // Instantiate ring of 8 LIF neurons
  genvar i;
  generate
      for (i = 0; i < 8; i = i + 1) begin : neurons
          lif neuron (
              .clk(clk && ena),
              .reset_n(rst_n),
              .current(coupling_currents[i]),
              .external_input(external_input + i),
              .state(states[i]),
              .spike(spikes[i])
          );
      end
  endgenerate

  // Output assignments
  assign uo_out = spikes;
  assign uio_out = states[0];
  assign uio_oe = 8'hFF;  // Set all bidirectional pins as outputs

endmodule
