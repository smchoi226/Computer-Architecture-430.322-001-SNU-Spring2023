// branch_target_buffer.v

/* The branch target buffer (BTB) stores the branch target address for
 * a branch PC. Our BTB is essentially a direct-mapped cache.
 */

module branch_target_buffer #(
  parameter DATA_WIDTH = 32,
  parameter NUM_ENTRIES = 256
) (
  input clk,
  input rstn,

  // update interface
  input update,                              // when 'update' is true, we update the BTB entry
  input [DATA_WIDTH-1:0] resolved_pc,
  input [DATA_WIDTH-1:0] resolved_pc_target,

  // access interface
  input [DATA_WIDTH-1:0] pc,

  output reg hit,
  output reg [DATA_WIDTH-1:0] target_address
);

// TODO: Implement BTB
integer i;
reg [54:0] btb[NUM_ENTRIES-1:0];

always @(*) begin
  target_address = btb[pc[9:2]][DATA_WIDTH-1:0];
  hit = (btb[pc[9:2]][54] == 1'b1) && (btb[pc[9:2]][53:32] == pc[DATA_WIDTH-1:10]);
end

always @(posedge clk) begin
  if(rstn == 1'b0) begin
    for(i = 0; i < NUM_ENTRIES; i += 1) btb[i] <= 55'b0;
    hit <= 0;
    target_address <= 0;
  end
  else if(update == 1'b1) btb[resolved_pc[9:2]] <= {1'b1, resolved_pc[DATA_WIDTH-1:10], resolved_pc_target};
end

endmodule
