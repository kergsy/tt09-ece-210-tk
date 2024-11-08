`default_nettype none

module lif (
    input wire clk,
    input wire rst_n,
    input wire ena,
    input wire [4:0] base_current,
    input wire [7:0] coupling_in,
    input wire [2:0] pattern_select,
    input wire [7:0] phase_offset,
    output reg [7:0] membrane_potential,
    output reg spike
);

    // Parameters
    localparam THRESHOLD = 8'd200;
    localparam RESET_POTENTIAL = 8'd50;
    localparam LEAK_RATE = 8'd5;
    localparam REFRACTORY_PERIOD = 4'd10;

    // Internal signals
    reg [7:0] next_potential;
    reg [3:0] refractory_counter;
    reg [7:0] phase_counter;
    wire [7:0] total_current;
    wire in_refractory;
    wire in_phase;
    
    assign in_refractory = (refractory_counter != 0);
    assign in_phase = (phase_counter >= phase_offset);
    
    // Calculate total current based on pattern
    wire [7:0] excitation, inhibition;
    assign excitation = coupling_in << 1; // 2x stronger excitation
    assign inhibition = coupling_in << 2; // 4x stronger inhibition
    
    // Pattern select:
    // 000: Independent firing
    // 001: Synchronized firing (strong excitation)
    // 010: Opposed firing (strong inhibition)
    // 011: Weak coupling
    assign total_current = 
        (pattern_select == 3'b000) ? {3'b0, base_current} :
        (pattern_select == 3'b001) ? {3'b0, base_current} + excitation :
        (pattern_select == 3'b010) ? (in_phase ? {3'b0, base_current} : 8'd0) - inhibition :
        (pattern_select == 3'b011) ? {3'b0, base_current} + {1'b0, coupling_in[7:1]} : // Half strength coupling
        {3'b0, base_current};

    // Membrane potential update logic
    always @(*) begin
        if (membrane_potential >= THRESHOLD) begin
            next_potential = RESET_POTENTIAL;
        end else if (in_refractory) begin
            next_potential = RESET_POTENTIAL;
        end else begin
            // Add current, subtract leak
            if (membrane_potential > LEAK_RATE) begin
                next_potential = membrane_potential + total_current - LEAK_RATE;
            end else begin
                next_potential = membrane_potential + total_current;
            end
        end
    end

    // Sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            membrane_potential <= RESET_POTENTIAL;
            spike <= 1'b0;
            refractory_counter <= 4'd0;
            phase_counter <= 8'd0;
        end else if (ena) begin
            membrane_potential <= next_potential;
            phase_counter <= phase_counter + 1;
            
            // Spike and refractory period logic
            if (membrane_potential >= THRESHOLD) begin
                spike <= 1'b1;
                refractory_counter <= REFRACTORY_PERIOD;
            end else begin
                spike <= 1'b0;
                refractory_counter <= (refractory_counter > 0) ? refractory_counter - 1 : 0;
            end
        end
    end

endmodule