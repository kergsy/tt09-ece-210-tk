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

    // Registered inputs
    reg [2:0] pattern_select_reg;
    reg [4:0] base_current_scale_reg;
    reg [7:0] coupling_strength_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern_select_reg <= 3'b0;
            base_current_scale_reg <= 5'b0;
            coupling_strength_reg <= 8'b0;
        end else begin
            pattern_select_reg <= ui_in[2:0];
            base_current_scale_reg <= ui_in[7:3];
            coupling_strength_reg <= uio_in;
        end
    end

    // Pattern-specific parameters
    reg [7:0] external_input_reg;

    // Registered pattern parameter selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            external_input_reg <= 8'b0;
        end else begin
            external_input_reg <= {base_current_scale_reg, 3'b000};
        end
    end

    // Internal signals
    wire [3:0] spikes;  // Adjusted to 4 bits for 4 neurons
    wire [7:0] states [3:0];  // Adjusted to 4 neurons
    reg  [7:0] coupling_currents [3:0];  // Adjusted to 4 neurons

    // Calculate coupling currents based on pattern with registered logic
    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : coupling_calc  // Adjusted loop to 4 iterations
            reg [3:0] spike_history;  // Adjusted to 4 bits for 4 neurons
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    spike_history <= 4'b0;
                    coupling_currents[j] <= 8'b0;
                end else begin
                    // Register spike history
                    spike_history <= spikes;
                    
                    // Registered coupling current calculation
                    case (pattern_select_reg)
                        3'b001: begin // Wave
                            coupling_currents[j] <= spike_history[(j+3) % 4] ? 
                                                  coupling_strength_reg : 8'd0;
                        end
                        3'b010: begin // Synchronous
                            coupling_currents[j] <= (|spike_history) ? 
                                                  coupling_strength_reg : 8'd0;
                        end
                        3'b011: begin // Clustered
                            coupling_currents[j] <= spike_history[(j+2) % 4] ? 
                                                  coupling_strength_reg : 8'd0;
                        end
                        3'b100: begin // Burst
                            coupling_currents[j] <= (spike_history[(j+3) % 4] || 
                                                   spike_history[(j+1) % 4]) ? 
                                                  coupling_strength_reg : 8'd0;
                        end
                        default: begin
                            coupling_currents[j] <= 8'd0;
                        end
                    endcase
                end
            end
        end
    endgenerate

    // Clock gating cell (simplified for simulation)
    wire gated_clk;
    assign gated_clk = clk & ena;

    // Instantiate ring of 4 LIF neurons
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : neurons  // Adjusted loop to 4 iterations
            lif neuron (
                .clk(gated_clk),
                .reset_n(rst_n),
                .current(coupling_currents[i]),
                .external_input(external_input_reg + i),
                .state(states[i]),
                .spike(spikes[i])
            );
        end
    endgenerate

    // Output assignments
    assign uo_out = {4'b0, spikes};  // Adjusted to fit 4 spikes into 8 bits
    assign uio_out = states[0];
    assign uio_oe = 8'hFF;  // Set all bidirectional pins as outputs

endmodule