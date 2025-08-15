// forwarding.v

// This module determines if the values need to be forwarded to the EX stage.

// TODO: declare propoer input and output ports and implement the
// forwarding unit

module forwarding (
  input [4:0] ex_rs1,
  input [4:0] ex_rs2,
  input [4:0] mem_rd,
  input [4:0] wb_rd,
  input mem_regwrite,
  input wb_regwrite,

  output reg [1:0] alusrc1,
  output reg [1:0] alusrc2
);

always @(*) begin
  if(ex_rs1 != 0 && ex_rs1 == mem_rd && mem_regwrite) alusrc1 = 2'b00;
  else if(ex_rs1 != 0 && ex_rs1 == wb_rd && wb_regwrite) alusrc1 = 2'b01;
  else alusrc1 = 2'b10;

  if(ex_rs2 != 0 && ex_rs2 == mem_rd && mem_regwrite) alusrc2 = 2'b00;
  else if(ex_rs2 != 0 && ex_rs2 == wb_rd && wb_regwrite) alusrc2 = 2'b01;
  else alusrc2 = 2'b10;
end

endmodule