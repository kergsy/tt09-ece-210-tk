/*
 * Copyright (c) 2024 Taylor Kergan
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_lif_tk (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // Parameters
    parameter N = 8; // Number of neurons

    // Neuron states and spikes
    wire [7:0] neuron_state [0:N-1];
    wire neuron_spike [0:N-1];

    // Instantiate neurons in a ring
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : neuron_ring
            lif lif_inst (
                .current(neuron_spike[(i + N - 1) % N] ? 8'hFF : 8'h00), // Input from previous neuron
                .external_input(ui_in),
                .clk(clk),
                .reset_n(rst_n),
                .state(neuron_state[i]),
                .spike(neuron_spike[i])
            );
        end
    endgenerate

    // Output logic
    assign uo_out = neuron_state[0]; // Example: output the state of the first neuron
    assign uio_out = {neuron_spike[0], 7'b0}; // Example: output the spike of the first neuron
    assign uio_oe  = 8'b00000001; // Enable output for the first spike

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, clk, rst_n, 1'b0};

endmodule
