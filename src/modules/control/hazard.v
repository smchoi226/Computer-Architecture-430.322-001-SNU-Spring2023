// hazard.v

// This module determines if pipeline stalls or flushing are required

// TODO: declare propoer input and output ports and implement the
// hazard detection unit

module hazard (
  input clk,
  input branch,
  input taken,
  input [1:0] jump,
  input [31:0] predicted_target,
  input [31:0] real_target,
  input [4:0] rs1,
  input [4:0] rs2,
  input [4:0] ex_rd,
  input ex_memread,
  input [6:0] opcode,

  output reg flush,
  output stall
);

reg use_rs1;
reg use_rs2;

always @(negedge clk) begin
  flush <= (branch || (jump != 0)) && (predicted_target != real_target);
  use_rs1 <= (opcode == 7'b0110011 || opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b0100011 || opcode == 7'b1100011 || opcode == 7'b1100111) && rs1 != 0;
  use_rs2 <= (opcode == 7'b0110011 || opcode == 7'b0100011 || opcode == 7'b1100011) && rs2 != 0;
  // stall <= ((rs1 == ex_rd && use_rs1) || (rs2 == ex_rd && use_rs2)) && ex_memread;
end

assign stall = ((rs1 == ex_rd && use_rs1) || (rs2 == ex_rd && use_rs2)) && ex_memread;

endmodule
