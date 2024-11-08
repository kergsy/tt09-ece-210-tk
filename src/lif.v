`default_nettype none

module lif (
  input wire [7:0]    current,
  input wire [7:0]    external_input,
  input wire          clk,
  input wire          reset_n,
  output reg [7:0]    state,
  output wire         spike
);

  // Fixed parameters
  localparam [7:0] THRESHOLD = 8'd200;
  localparam [7:0] DECAY = 8'd1;
  localparam [3:0] REFRACTORY_PERIOD = 4'd4;

  reg refractory;
  reg [3:0] refractory_counter;

  assign spike = (state >= THRESHOLD) && !refractory;

  wire [7:0] total_input = current + external_input;
  wire [7:0] leak_amount = (state > DECAY) ? DECAY : state;
  wire [7:0] next_state = (!refractory && state < THRESHOLD) ? 
                         (state + total_input - leak_amount) : 
                         8'd0;

  always @(posedge clk or negedge reset_n) begin
      if (!reset_n) begin
          state <= 8'd0;
          refractory <= 1'b0;
          refractory_counter <= 4'd0;
      end else begin
          if (refractory) begin
              refractory_counter <= refractory_counter + 1;
              if (refractory_counter >= REFRACTORY_PERIOD) begin
                  refractory <= 1'b0;
                  refractory_counter <= 4'd0;
              end
          end else begin
              state <= next_state;
              if (spike) begin
                  state <= 8'd0;
                  refractory <= 1'b1;
              end
          end
      end
  end

endmodule