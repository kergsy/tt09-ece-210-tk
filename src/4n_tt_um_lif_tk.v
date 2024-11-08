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

    // External input calculation with added pipeline stage
    reg [7:0] external_input_reg;
    reg [7:0] external_input_reg_d1; // Delayed version

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            external_input_reg <= 8'b0;
            external_input_reg_d1 <= 8'b0;
        end else begin
            external_input_reg <= {base_current_scale_reg, 3'b000};
            external_input_reg_d1 <= external_input_reg;
        end
    end

    // Internal signals
    wire [3:0] spikes;               // Spikes from each neuron
    wire [7:0] states [0:3];         // States of each neuron
    reg  [7:0] coupling_currents [0:3]; // Coupling currents for each neuron

    // Spike history registers with added delay stages
    reg [3:0] spike_history_d1;
    reg [3:0] spike_history_d2;
    reg [3:0] spike_history_d3; // Additional pipeline stage

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            spike_history_d1 <= 4'b0;
            spike_history_d2 <= 4'b0;
            spike_history_d3 <= 4'b0;
        end else begin
            spike_history_d1 <= spikes;
            spike_history_d2 <= spike_history_d1;
            spike_history_d3 <= spike_history_d2;
        end
    end

    // Calculate coupling currents based on pattern using delayed spike history
    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1) begin : coupling_calc
            // Local parameters for index calculations
            localparam integer idx_minus1 = (j + 3) % 4; // Equivalent to (j - 1) mod 4
            localparam integer idx_minus2 = (j + 2) % 4; // Equivalent to (j - 2) mod 4
            localparam integer idx_plus1  = (j + 1) % 4; // Equivalent to (j + 1) mod 4

            reg [7:0] coupling_current_temp;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    coupling_current_temp <= 8'd0;
                    coupling_currents[j] <= 8'd0;
                end else begin
                    // Calculate coupling current based on the selected pattern using delayed spike history
                    case (pattern_select_reg)
                        3'b001: begin // Wave pattern
                            coupling_current_temp <= spike_history_d3[idx_minus1] ? coupling_strength_reg : 8'd0;
                        end
                        3'b010: begin // Synchronous pattern
                            coupling_current_temp <= (|spike_history_d3) ? coupling_strength_reg : 8'd0;
                        end
                        3'b011: begin // Clustered pattern
                            coupling_current_temp <= spike_history_d3[idx_minus2] ? coupling_strength_reg : 8'd0;
                        end
                        3'b100: begin // Burst pattern
                            coupling_current_temp <= (spike_history_d3[idx_minus1] || spike_history_d3[idx_plus1]) ? 
                                                  coupling_strength_reg : 8'd0;
                        end
                        default: begin
                            coupling_current_temp <= 8'd0;
                        end
                    endcase
                    // Register the coupling current to introduce delay
                    coupling_currents[j] <= coupling_current_temp;
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
        for (i = 0; i < 4; i = i + 1) begin : neurons
            lif neuron (
                .clk(gated_clk),
                .reset_n(rst_n),
                .current(coupling_currents[i]),
                .external_input(external_input_reg_d1 + i), // Use delayed external input
                .state(states[i]),
                .spike(spikes[i])
            );
        end
    endgenerate

    // Output assignments
    assign uo_out = {4'b0, spikes};  // Output the spikes from neurons
    assign uio_out = states[0];      // Output the state of the first neuron
    assign uio_oe = 8'hFF;           // Enable all bidirectional pins as outputs

endmodule