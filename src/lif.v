`default_nettype none

module lif (
    input wire [7:0]    current,
    input wire [7:0]    external_input,
    input wire          clk,
    input wire          reset_n,
    output reg [7:0]    state,
    output wire         spike
);

wire [7:0] next_state;
reg [7:0] threshold;
reg [7:0] decay;
reg refractory;
reg [3:0] refractory_counter;

always @(posedge clk) begin
    if (!reset_n) begin
        state <= 0;
        threshold <= 200;
        decay <= 1;
        refractory <= 0;
        refractory_counter <= 0;
    end else begin
        if (refractory) begin
            refractory_counter <= refractory_counter + 1;
            if (refractory_counter >= 4) begin
                refractory <= 0;
                refractory_counter <= 0;
            end
        end else begin
            state <= next_state;
            if (state >= threshold) begin
                state <= 0;
                refractory <= 1;
            end
        end
    end
end

assign next_state = current + external_input + (state >> 1) - decay;
assign spike = (state >= threshold) && !refractory;

endmodule