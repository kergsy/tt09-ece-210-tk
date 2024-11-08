`default_nettype none

module lif (
    input  wire [7:0] current,
    input  wire [7:0] external_input,
    input  wire       clk,
    input  wire       reset_n,
    output reg  [7:0] state,
    output reg        spike
);

    // Fixed parameters
    localparam [7:0] THRESHOLD = 8'd200;
    localparam [7:0] DECAY = 8'd1;
    localparam [3:0] REFRACTORY_PERIOD = 4'd4;

    // Registered inputs
    reg [7:0] current_reg;
    reg [7:0] external_input_reg;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_reg <= 8'd0;
            external_input_reg <= 8'd0;
        end else begin
            current_reg <= current;
            external_input_reg <= external_input;
        end
    end

    reg refractory;
    reg [3:0] refractory_counter;
    reg [7:0] next_state_reg;

    // Pipeline the state calculation with additional stage for adder_result
    reg [7:0] total_input_reg;
    reg [7:0] leak_amount_reg;
    reg [7:0] adder_result;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            total_input_reg <= 8'd0;
            leak_amount_reg <= 8'd0;
            adder_result <= 8'd0;
            next_state_reg <= 8'd0;
        end else begin
            total_input_reg <= current_reg + external_input_reg;
            leak_amount_reg <= (state > DECAY) ? DECAY : state;
            adder_result <= state + total_input_reg;
            next_state_reg <= (!refractory && state < THRESHOLD) ? (adder_result - leak_amount_reg) : 8'd0;
        end
    end

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= 8'd0;
            refractory <= 1'b0;
            refractory_counter <= 4'd0;
            spike <= 1'b0; // Initialize spike to 0
        end else begin
            if (refractory) begin
                refractory_counter <= refractory_counter + 1;
                if (refractory_counter >= REFRACTORY_PERIOD) begin
                    refractory <= 1'b0;
                    refractory_counter <= 4'd0;
                end
                spike <= 1'b0; // No spike during refractory
            end else begin
                state <= next_state_reg;
                if (state >= THRESHOLD) begin
                    state <= 8'd0;
                    refractory <= 1'b1;
                    spike <= 1'b1; // Register the spike
                end else begin
                    spike <= 1'b0; // No spike if threshold not reached
                end
            end
        end
    end

endmodule