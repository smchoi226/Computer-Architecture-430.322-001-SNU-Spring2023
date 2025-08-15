// gshare.v

/* The Gshare predictor consists of the global branch history register (BHR)
 * and a pattern history table (PHT). Note that PC[1:0] is not used for
 * indexing.
 */

module gshare #(
  parameter DATA_WIDTH = 32,
  parameter COUNTER_WIDTH = 2,
  parameter NUM_ENTRIES = 256
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

// TODO: Implement gshare branch predictor
integer i;
reg [7:0] bhr;
reg [COUNTER_WIDTH-1:0] pht [NUM_ENTRIES-1:0];

always @(*) begin
  pred = (pht[pc[9:2] ^ bhr] == 2'b10) || (pht[pc[9:2] ^ bhr] == 2'b11);
end

always @(posedge clk) begin
  if(rstn == 1'b0) begin
    for(i = 0; i < NUM_ENTRIES; i += 1) begin
      pht[i] <= 2'b01;
    end
    bhr <= 8'b0;
    pred <= 1'b0;
  end
  else if(update == 1'b1) begin
    if(actually_taken == 1'b1) begin
      case(pht[resolved_pc[9:2] ^ bhr])
        2'b00: pht[resolved_pc[9:2] ^ bhr] <= 2'b01;
        2'b01: pht[resolved_pc[9:2] ^ bhr] <= 2'b10;
        2'b10: pht[resolved_pc[9:2] ^ bhr] <= 2'b11;
        2'b11: pht[resolved_pc[9:2] ^ bhr] <= 2'b11;
        default: pht[resolved_pc[9:2] ^ bhr] <= 2'b00;
      endcase
    end
    else begin
      case(pht[resolved_pc[9:2] ^ bhr])
        2'b00: pht[resolved_pc[9:2] ^ bhr] <= 2'b00;
        2'b01: pht[resolved_pc[9:2] ^ bhr] <= 2'b00;
        2'b10: pht[resolved_pc[9:2] ^ bhr] <= 2'b01;
        2'b11: pht[resolved_pc[9:2] ^ bhr] <= 2'b10;
        default: pht[resolved_pc[9:2] ^ bhr] <= 2'b00;
      endcase
    end
    bhr <= {bhr[6:0], actually_taken};
  end
end

endmodule
