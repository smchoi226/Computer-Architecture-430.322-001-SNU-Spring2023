// idex_reg.v
// This module is the ID/EX pipeline register.


module idex_reg #(
  parameter DATA_WIDTH = 32
)(
  // TODO: Add flush or stall signal if it is needed

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] id_PC,
  input [DATA_WIDTH-1:0] id_pc_plus_4,

  // ex control
  input [1:0] id_jump,
  input id_branch,
  input [1:0] id_aluop,
  input id_alusrc,

  // mem control
  input id_memread,
  input id_memwrite,

  // wb control
  input id_memtoreg,
  input id_regwrite,
  input [1:0] id_lui,  

  input [DATA_WIDTH-1:0] id_sextimm,
  input [6:0] id_funct7,
  input [2:0] id_funct3,
  input [DATA_WIDTH-1:0] id_readdata1,
  input [DATA_WIDTH-1:0] id_readdata2,
  input [4:0] id_rs1,
  input [4:0] id_rs2,
  input [4:0] id_rd,

  input flush,
  input stall,

  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output reg [DATA_WIDTH-1:0] ex_PC,
  output reg [DATA_WIDTH-1:0] ex_pc_plus_4,

  // ex control
  output reg ex_branch,
  output reg [1:0] ex_aluop,
  output reg ex_alusrc,
  output reg [1:0] ex_jump,

  // mem control
  output reg ex_memread,
  output reg ex_memwrite,

  // wb control
  output reg ex_memtoreg,
  output reg ex_regwrite,
  output reg [1:0] ex_lui,

  output reg [DATA_WIDTH-1:0] ex_sextimm,
  output reg [6:0] ex_funct7,
  output reg [2:0] ex_funct3,
  output reg [DATA_WIDTH-1:0] ex_readdata1,
  output reg [DATA_WIDTH-1:0] ex_readdata2,
  output reg [4:0] ex_rs1,
  output reg [4:0] ex_rs2,
  output reg [4:0] ex_rd
);

// TODO: Implement ID/EX pipeline register module
always @(posedge clk) begin
  if(flush || stall) begin
    ex_PC <= 0;
    ex_pc_plus_4 <= 0;
    ex_branch <= 0;
    ex_aluop <= 0;
    ex_alusrc <= 0;
    ex_jump <= 0;
    ex_memread <= 0;
    ex_memwrite <= 0;
    ex_memtoreg <= 0;
    ex_regwrite <= 0;
    ex_lui <= 0;
    ex_sextimm <= 0;
    ex_funct7 <= 0;
    ex_funct3 <= 0;
    ex_readdata1 <= 0;
    ex_readdata2 <= 0;
    ex_rs1 <= 0;
    ex_rs2 <= 0;
    ex_rd <= 0;
  end
  else begin
    ex_PC <= id_PC;
    ex_pc_plus_4 <= id_pc_plus_4;
    ex_branch <= id_branch;
    ex_aluop <= id_aluop;
    ex_alusrc <= id_alusrc;
    ex_jump <= id_jump;
    ex_memread <= id_memread;
    ex_memwrite <= id_memwrite;
    ex_memtoreg <= id_memtoreg;
    ex_regwrite <= id_regwrite;
    ex_lui <= id_lui;
    ex_sextimm <= id_sextimm;
    ex_funct7 <= id_funct7;
    ex_funct3 <= id_funct3;
    ex_readdata1 <= id_readdata1;
    ex_readdata2 <= id_readdata2;
    ex_rs1 <= id_rs1;
    ex_rs2 <= id_rs2;
    ex_rd <= id_rd;
  end
end

endmodule
