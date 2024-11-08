// `default_nettype none

// module lif (
//     input  wire [7:0] current,
//     input  wire [7:0] external_input,
//     input  wire       clk,
//     input  wire       reset_n,
//     output reg  [7:0] state,
//     output reg        spike
// );

//     // Fixed parameters
//     localparam [7:0] THRESHOLD = 8'd200;
//     localparam [7:0] DECAY = 8'd1;
//     localparam [3:0] REFRACTORY_PERIOD = 4'd4;

//     // Registered inputs
//     reg [7:0] current_reg;
//     reg [7:0] external_input_reg;

//     always @(posedge clk or negedge reset_n) begin
//         if (!reset_n) begin
//             current_reg <= 8'd0;
//             external_input_reg <= 8'd0;
//         end else begin
//             current_reg <= current;
//             external_input_reg <= external_input;
//         end
//     end

//     reg refractory;
//     reg [3:0] refractory_counter;
//     reg [7:0] next_state_reg;

//     // Pipeline the state calculation with additional stage for adder_result
//     reg [7:0] total_input_reg;
//     reg [7:0] leak_amount_reg;
//     reg [7:0] adder_result;

//     always @(posedge clk or negedge reset_n) begin
//         if (!reset_n) begin
//             total_input_reg <= 8'd0;
//             leak_amount_reg <= 8'd0;
//             adder_result <= 8'd0;
//             next_state_reg <= 8'd0;
//         end else begin
//             total_input_reg <= current_reg + external_input_reg;
//             leak_amount_reg <= (state > DECAY) ? DECAY : state;
//             adder_result <= state + total_input_reg;
//             next_state_reg <= (!refractory && state < THRESHOLD) ? (adder_result - leak_amount_reg) : 8'd0;
//         end
//     end

//     always @(posedge clk or negedge reset_n) begin
//         if (!reset_n) begin
//             state <= 8'd0;
//             refractory <= 1'b0;
//             refractory_counter <= 4'd0;
//             spike <= 1'b0; // Initialize spike to 0
//         end else begin
//             if (refractory) begin
//                 refractory_counter <= refractory_counter + 1;
//                 if (refractory_counter >= REFRACTORY_PERIOD) begin
//                     refractory <= 1'b0;
//                     refractory_counter <= 4'd0;
//                 end
//                 spike <= 1'b0; // No spike during refractory
//             end else begin
//                 state <= next_state_reg;
//                 if (state >= THRESHOLD) begin
//                     state <= 8'd0;
//                     refractory <= 1'b1;
//                     spike <= 1'b1; // Register the spike
//                 end else begin
//                     spike <= 1'b0; // No spike if threshold not reached
//                 end
//             end
//         end
//     end

// endmodule

// `default_nettype none

// module lif (
//     input  wire [7:0] external_input,
//     input  wire       clk,
//     input  wire       reset_n,
//     output reg  [7:0] state,
//     output reg        spike
// );

//     // Fixed parameters
//     localparam [7:0] THRESHOLD = 8'd128;  // Lowered threshold for simplicity
//     localparam [7:0] DECAY = 8'd1;

//     // Registered external input
//     reg [7:0] external_input_reg;

//     always @(posedge clk or negedge reset_n) begin
//         if (!reset_n) begin
//             external_input_reg <= 8'd0;
//         end else begin
//             external_input_reg <= external_input;
//         end
//     end

//     // State update
//     always @(posedge clk or negedge reset_n) begin
//         if (!reset_n) begin
//             state <= 8'd0;
//             spike <= 1'b0;
//         end else begin
//             // Update state with external input and decay
//             state <= state + external_input_reg - ((state > DECAY) ? DECAY : state);

//             // Generate spike if threshold is reached
//             if (state >= THRESHOLD) begin
//                 spike <= 1'b1;
//                 state <= 8'd0;  // Reset state after spike
//             end else begin
//                 spike <= 1'b0;
//             end
//         end
//     end

// endmodule

`default_nettype none

module lif (
    input wire clk,
    input wire rst_n,
    input wire ena,
    input wire [4:0] base_current,
    input wire [7:0] coupling_in,
    input wire [2:0] pattern_select,
    output reg [7:0] membrane_potential,
    output reg spike
);

    // Parameters
    localparam THRESHOLD = 8'd200;
    localparam RESET_POTENTIAL = 8'd50;
    localparam LEAK_RATE = 8'd5;

    // Internal signals
    reg [7:0] next_potential;
    wire [7:0] total_current;
    
    // Calculate total input current based on pattern
    assign total_current = (pattern_select == 3'b000) ? {3'b0, base_current} :
                          (pattern_select == 3'b001) ? {3'b0, base_current} + coupling_in :
                          (pattern_select == 3'b010) ? {3'b0, base_current} - coupling_in :
                          {3'b0, base_current};

    // Membrane potential update logic
    always @(*) begin
        if (membrane_potential >= THRESHOLD) begin
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
        end else if (ena) begin
            membrane_potential <= next_potential;
            spike <= (membrane_potential >= THRESHOLD);
        end
    end

endmodule