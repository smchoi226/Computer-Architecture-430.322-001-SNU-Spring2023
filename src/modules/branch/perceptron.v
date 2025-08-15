// perceptron.v

/* The perceptron predictor uses the simplest form of neural networks
 * (perceptron), instead of using two-bit counters.  Note that PC[1:0] is not
 * used when indexing into the table of perceptrons.
 *
 * D. Jimenez and C. Lin. "Dynamic Branch Prediction with Perceptrons" HPCA 2001.
 */

module perceptron #(
  parameter DATA_WIDTH = 32,
  parameter HIST_LEN = 25, // Since x0 is always 1, 26 weights will reside in the perceptron table 
  parameter NUM_ENTRIES = 32
) (
  input clk,
  input rstn,

  // update interface
  input update,
  input actually_taken,
  input [DATA_WIDTH-1:0] resolved_pc,

  // access interface
  input [DATA_WIDTH-1:0] pc,

  output reg pred
);

// TODO: Implement the perceptron branch predictor
// NOTE: DO NOT CHANGE the local parameters
localparam INDEX_WIDTH     = $clog2(NUM_ENTRIES);
localparam THRESHOLD       = $rtoi($floor(1.93 * HIST_LEN + 14));
localparam WEIGHT_BITWIDTH = 1 + $clog2(THRESHOLD + 1);
localparam WEIGHT_MAX      = $signed({1'b0, {WEIGHT_BITWIDTH-1{1'b1}}});
localparam WEIGHT_MIN      = $signed({1'b1, {WEIGHT_BITWIDTH-1{1'b0}}});
localparam OUTPUT_BITWIDTH = 1 + $clog2((HIST_LEN + 1) * WEIGHT_MAX + 1);

integer i, j;
reg [HIST_LEN-1:0] bhr;
reg signed [WEIGHT_BITWIDTH-1:0] pht[NUM_ENTRIES-1:0][HIST_LEN:0];
reg signed [OUTPUT_BITWIDTH-1:0] out;
reg signed [OUTPUT_BITWIDTH-1:0] resolved_out;
reg resolved_pred;

always @(*) begin
  out = pht[pc[INDEX_WIDTH+1:2]][0];
  for(i = 1; i <= HIST_LEN; i += 1) begin
    if(bhr[i-1] == 1'b1) out = out + pht[pc[INDEX_WIDTH+1:2]][i];
    else out = out - pht[pc[INDEX_WIDTH+1:2]][i];
  end
  pred = (out >= 0);
  resolved_out = pht[resolved_pc[INDEX_WIDTH+1:2]][0];
  for(i = 1; i <= HIST_LEN; i += 1) begin
    if(bhr[i-1] == 1'b1) resolved_out = resolved_out + pht[resolved_pc[INDEX_WIDTH+1:2]][i];
    else resolved_out = resolved_out - pht[resolved_pc[INDEX_WIDTH+1:2]][i];
  end
  resolved_pred = (resolved_out >= 0);
end

always @(posedge clk) begin
  if(rstn == 1'b0) begin
    for(i = 0; i < HIST_LEN; i += 1) bhr[i] <= 0;
    for(i = 0; i < NUM_ENTRIES; i += 1) for(j = 0; j <= HIST_LEN; j += 1) pht[i][j] <= 0;
    out <= 0;
    resolved_out <= 0;
    pred <= 0;
    resolved_pred <= 0;
  end
  else if(update == 1'b1) begin
    if((actually_taken != resolved_pred) || (resolved_out <= THRESHOLD && resolved_out >= -THRESHOLD)) begin
      if(actually_taken == 1'b1) begin 
        if(pht[resolved_pc[INDEX_WIDTH+1:2]][0] < WEIGHT_MAX) pht[resolved_pc[INDEX_WIDTH+1:2]][0] <= pht[resolved_pc[INDEX_WIDTH+1:2]][0] + 1;
      end
      else begin
        if(pht[resolved_pc[INDEX_WIDTH+1:2]][0] > WEIGHT_MIN) pht[resolved_pc[INDEX_WIDTH+1:2]][0] <= pht[resolved_pc[INDEX_WIDTH+1:2]][0] - 1;
      end
      for(i = 1; i <= HIST_LEN; i += 1) begin
        if(actually_taken == bhr[i-1]) begin 
          if(pht[resolved_pc[INDEX_WIDTH+1:2]][i] < WEIGHT_MAX) pht[resolved_pc[INDEX_WIDTH+1:2]][i] <= pht[resolved_pc[INDEX_WIDTH+1:2]][i] + 1;
        end
        else begin
          if(pht[resolved_pc[INDEX_WIDTH+1:2]][i] > WEIGHT_MIN) pht[resolved_pc[INDEX_WIDTH+1:2]][i] <= pht[resolved_pc[INDEX_WIDTH+1:2]][i] - 1;
        end
      end
    end
    bhr <= {bhr[HIST_LEN-2:0], actually_taken};
  end
end

endmodule