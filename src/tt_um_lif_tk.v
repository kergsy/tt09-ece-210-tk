`default_nettype none

module tt_um_lif_tk (
    input  wire [7:0] ui_in,    // Inputs: [2:0] pattern_select, [7:3] base_current
    input  wire [7:0] uio_in,   // IOs: Coupling strength
    output wire [7:0] uo_out,   // Outputs: Spikes
    output wire [7:0] uio_out,  // IOs: First neuron state
    output wire [7:0] uio_oe,   // IOs: Enable path
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Internal signals
    wire [7:0] neuron1_state, neuron2_state;
    wire neuron1_spike, neuron2_spike;
    wire [4:0] base_current;
    wire [2:0] pattern_select;
    wire [7:0] coupling_strength;

    // Assign inputs
    assign base_current = ui_in[7:3];
    assign pattern_select = ui_in[2:0];
    assign coupling_strength = uio_in;

    // Phase offsets for the neurons
    localparam PHASE1 = 8'd0;
    localparam PHASE2 = 8'd100;  // Half period offset

    // Instantiate two LIF neurons
    lif neuron1 (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .base_current(base_current),
        .coupling_in(neuron2_spike ? coupling_strength : 8'b0),
        .pattern_select(pattern_select),
        .phase_offset(PHASE1),
        .membrane_potential(neuron1_state),
        .spike(neuron1_spike)
    );

    lif neuron2 (
        .clk(clk),
        .rst_n(rst_n),
        .ena(ena),
        .base_current(base_current),
        .coupling_in(neuron1_spike ? coupling_strength : 8'b0),
        .pattern_select(pattern_select),
        .phase_offset(PHASE2),
        .membrane_potential(neuron2_state),
        .spike(neuron2_spike)
    );

    // Assign outputs
    assign uo_out = {6'b0, neuron2_spike, neuron1_spike};
    assign uio_out = neuron1_state;
    assign uio_oe = 8'b0;  // Set as inputs

endmodule