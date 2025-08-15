// simple_cpu.v
// a pipelined RISC-V microarchitecture (RV32I)

///////////////////////////////////////////////////////////////////////////////////////////
//// [*] In simple_cpu.v you should connect the correct wires to the correct ports
////     - All modules are given so there is no need to make new modules
////       (it does not mean you do not need to instantiate new modules)
////     - However, you may have to fix or add in / out ports for some modules
////     - In addition, you are still free to instantiate simple modules like multiplexers,
////       adders, etc.
///////////////////////////////////////////////////////////////////////////////////////////

module simple_cpu
#(parameter DATA_WIDTH = 32)(
  input clk,
  input rstn
);

///////////////////////////////////////////////////////////////////////////////
// TODO:  Declare all wires / registers that are needed
///////////////////////////////////////////////////////////////////////////////
// e.g., wire [DATA_WIDTH-1:0] if_pc_plus_4;
// 1) Pipeline registers (wires to / from pipeline register modules)
// 2) In / Out ports for other modules
// 3) Additional wires for multiplexers or other mdoules you instantiate

wire [31:0] CORE_CYCLE;
wire [31:0] NUM_COND_BRANCHES;
wire [31:0] NUM_UNCOND_BRANCHES;
wire [31:0] BP_CORRECT;

wire is_jump;
wire is_correct;

reg [DATA_WIDTH-1:0] PC;    // program counter (32 bits)
wire [DATA_WIDTH-1:0] pc_plus_4;
wire [DATA_WIDTH-1:0] branch_target_pc;
wire [DATA_WIDTH-1:0] stall_next_pc;
wire [DATA_WIDTH-1:0] NEXT_PC;
wire [DATA_WIDTH-1:0] instruction;

wire flush;
wire stall;

wire take_predicted;
wire pre_branch;
wire pre_jump;
wire update_btb;
wire hit;
wire pred_taken;
wire pred_taken_filtered;
wire [DATA_WIDTH-1:0] target_address;

wire [DATA_WIDTH-1:0] id_pc;
wire [DATA_WIDTH-1:0] id_pc_plus_4;
wire [DATA_WIDTH-1:0] id_instruction;
wire [1:0] id_jump;
wire id_branch;
wire [1:0] id_aluop;    
wire id_alusrc;   
wire id_memread;  
wire id_memwrite;
wire id_memtoreg; 
wire id_regwrite;
wire [1:0] id_lui;
wire [DATA_WIDTH-1:0] id_sextimm;
wire [DATA_WIDTH-1:0] id_readdata1;
wire [DATA_WIDTH-1:0] id_readdata2;

wire [DATA_WIDTH-1:0] ex_pc;
wire [DATA_WIDTH-1:0] ex_pc_plus_4;
wire [1:0]ex_jump;
wire ex_branch;
wire [1:0] ex_aluop;    
wire ex_alusrc;   
wire ex_memwrite;
wire ex_memread;  
wire ex_memtoreg; 
wire ex_regwrite;
wire [1:0] ex_lui;
wire [DATA_WIDTH-1:0] ex_sextimm;  
wire [6:0] ex_funct7;
wire [2:0] ex_funct3;
wire [DATA_WIDTH-1:0] ex_readdata1;
wire [DATA_WIDTH-1:0] ex_readdata2;
wire [4:0] ex_rs1;
wire [4:0] ex_rs2;
wire [4:0] ex_rd;
wire [DATA_WIDTH-1:0] ex_pc_target;
wire ex_check;
wire ex_taken;
wire [3:0] ex_alu_func;
wire [1:0] ex_alusrc1;
wire [1:0] ex_alusrc2;
wire [DATA_WIDTH-1:0] ex_selected_data;
wire [DATA_WIDTH-1:0] ex_aluin1;
wire [DATA_WIDTH-1:0] ex_aluin2;
wire [DATA_WIDTH-1:0] ex_alu_result;
wire [DATA_WIDTH-1:0] ex_regdata;

wire [DATA_WIDTH-1:0] mem_pc;
wire [DATA_WIDTH-1:0] mem_alu_result;
wire mem_taken;
wire [1:0] mem_jump;
wire mem_regwrite;  
wire [4:0] mem_rd;
wire [DATA_WIDTH-1:0] mem_pc_plus_4;
wire [DATA_WIDTH-1:0] mem_pc_target; 
wire [DATA_WIDTH-1:0] mem_branch_next_pc;
wire mem_branch;
wire mem_memread;
wire mem_memwrite;   
wire mem_memtoreg;
wire [DATA_WIDTH-1:0] mem_writedata;
wire [2:0] mem_funct3; 
wire [DATA_WIDTH-1:0] mem_pc_result;
wire [DATA_WIDTH-1:0] mem_readdata;
wire [DATA_WIDTH-1:0] mem_data;
wire [DATA_WIDTH-1:0] mem_regdata;

wire [DATA_WIDTH-1:0] wb_pc_plus_4;
wire [1:0] wb_jump;  
wire wb_memtoreg;
wire wb_regwrite;
wire [4:0] wb_rd;
wire [DATA_WIDTH-1:0] wb_readdata;  
wire [DATA_WIDTH-1:0] wb_alu_result;
wire [DATA_WIDTH-1:0] wb_data;
wire [DATA_WIDTH-1:0] wb_regdata;

///////////////////////////////////////////////////////////////////////////////
// Task Statistics
///////////////////////////////////////////////////////////////////////////////

hardware_counter m_core_cycle(
  .clk(clk),
  .rstn(rstn),
  .cond(1'b1),

  .counter(CORE_CYCLE)
);

hardware_counter m_cond_branch(
  .clk(clk),
  .rstn(rstn),
  .cond(mem_branch),

  .counter(NUM_COND_BRANCHES)
);

assign is_jump = mem_jump != 0;
hardware_counter m_uncond_branch(
  .clk(clk),
  .rstn(rstn),
  .cond(is_jump),

  .counter(NUM_UNCOND_BRANCHES)
);

assign is_correct = mem_branch && (ex_pc == mem_branch_next_pc);
hardware_counter m_bp_correct(
  .clk(clk),
  .rstn(rstn),
  .cond(is_correct),

  .counter(BP_CORRECT)
);

///////////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
///////////////////////////////////////////////////////////////////////////////

/* m_next_pc_adder */
adder m_pc_plus_4_adder(
  .in_a   (PC),
  .in_b(32'h0000_0004),

  .result (pc_plus_4)
);

assign take_predicted = (pre_branch && hit && pred_taken_filtered) || (pre_jump && hit);

mux_2x1 m_mux_2x1_btbpc(
  .select (take_predicted),
  .in1 (pc_plus_4),
  .in2 (target_address),
  .out (branch_target_pc)
);

mux_2x1 m_mux_2x1_stallpc(
  .select (stall),
  .in1 (branch_target_pc),
  .in2 (PC),
  .out (stall_next_pc)
);

mux_2x1 m_mux_2x1_pc(
  .select (flush),
  .in1 (stall_next_pc),
  .in2 (mem_branch_next_pc),
  .out (NEXT_PC)
);

always @(posedge clk) begin
  if (rstn == 1'b0) begin
    PC <= 32'h00000000;
  end
  else PC <= NEXT_PC;
end

/* instruction: read current instruction from inst mem */
instruction_memory m_instruction_memory(
  .address    (PC),

  .instruction(instruction)
);

assign pre_branch = instruction[6:0] == 7'b1100011;
assign pre_jump = (instruction[6:0] == 7'b1101111 || instruction[6:0] == 7'b1100111);
assign update_btb = mem_taken || (mem_jump != 0);
assign pred_taken_filtered = (pred_taken === 1'bz) ? 1'b0 : pred_taken;

branch_hardware m_branch_hardware(
  .clk (clk),
  .rstn (rstn),

  // update interface
  .update_predictor (mem_branch),
  .update_btb (update_btb),
  .actually_taken (mem_taken),
  .resolved_pc (mem_pc),
  .resolved_pc_target (mem_branch_next_pc),  // actual target address when the branch is resolved.

  // access interface
  .pc (PC),

  .hit (hit),          // btb hit or not
  .pred (pred_taken),         // predicted taken or not
  .branch_target (target_address)  // branch target address for a hit
);

/* forward to IF/ID stage registers */
ifid_reg m_ifid_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .if_PC          (PC),
  .if_pc_plus_4   (pc_plus_4),
  .if_instruction (instruction),
  .flush          (flush),
  .stall          (stall),

  .id_PC          (id_pc),
  .id_pc_plus_4   (id_pc_plus_4),
  .id_instruction (id_instruction)
);


//////////////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////////////

/* m_hazard: hazard detection unit */
hazard m_hazard(
  // TODO: implement hazard detection unit & do wiring
  .clk (clk),
  .branch (mem_branch),
  .taken (mem_taken),
  .jump (mem_jump),
  .predicted_target (ex_pc),
  .real_target (mem_branch_next_pc),
  .rs1 (id_instruction[19:15]),
  .rs2 (id_instruction[24:20]),
  .ex_rd (ex_rd),
  .ex_memread (ex_memread),
  .opcode (id_instruction[6:0]),

  .flush (flush),
  .stall (stall)
);

/* m_control: control unit */
control m_control(
  .opcode     (id_instruction[6:0]),

  .jump       (id_jump),
  .branch     (id_branch),
  .alu_op     (id_aluop),
  .alu_src    (id_alusrc),
  .mem_read   (id_memread),
  .mem_to_reg (id_memtoreg),
  .mem_write  (id_memwrite),
  .reg_write  (id_regwrite),
  .lui        (id_lui)
);

/* m_imm_generator: immediate generator */
immediate_generator m_immediate_generator(
  .instruction(id_instruction),

  .sextimm    (id_sextimm)
);

/* m_register_file: register file */
register_file m_register_file(
  .clk        (clk),
  .readreg1   (id_instruction[19:15]),
  .readreg2   (id_instruction[24:20]),
  .writereg   (wb_rd),
  .wen        (wb_regwrite),
  .writedata  (wb_regdata),

  .readdata1  (id_readdata1),
  .readdata2  (id_readdata2)
);

/* forward to ID/EX stage registers */
idex_reg m_idex_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk          (clk),
  .id_PC        (id_pc),
  .id_pc_plus_4 (id_pc_plus_4),
  .id_jump      (id_jump),
  .id_branch    (id_branch),
  .id_aluop     (id_aluop),
  .id_alusrc    (id_alusrc),
  .id_memread   (id_memread),
  .id_memwrite  (id_memwrite),
  .id_memtoreg  (id_memtoreg),
  .id_regwrite  (id_regwrite),
  .id_lui       (id_lui),
  .id_sextimm   (id_sextimm),
  .id_funct7    (id_instruction[31:25]),
  .id_funct3    (id_instruction[14:12]),
  .id_readdata1 (id_readdata1),
  .id_readdata2 (id_readdata2),
  .id_rs1       (id_instruction[19:15]),
  .id_rs2       (id_instruction[24:20]),
  .id_rd        (id_instruction[11:7]),
  .flush        (flush),
  .stall        (stall),

  .ex_PC        (ex_pc),
  .ex_pc_plus_4 (ex_pc_plus_4),
  .ex_jump      (ex_jump),
  .ex_branch    (ex_branch),
  .ex_aluop     (ex_aluop),
  .ex_alusrc    (ex_alusrc),
  .ex_memread   (ex_memread),
  .ex_memwrite  (ex_memwrite),
  .ex_memtoreg  (ex_memtoreg),
  .ex_regwrite  (ex_regwrite),
  .ex_lui       (ex_lui),
  .ex_sextimm   (ex_sextimm),
  .ex_funct7    (ex_funct7),
  .ex_funct3    (ex_funct3),
  .ex_readdata1 (ex_readdata1),
  .ex_readdata2 (ex_readdata2),
  .ex_rs1       (ex_rs1),
  .ex_rs2       (ex_rs2),
  .ex_rd        (ex_rd)
);

//////////////////////////////////////////////////////////////////////////////////
// Execute (EX) 
//////////////////////////////////////////////////////////////////////////////////

/* m_branch_target_adder: PC + imm for branch address */
adder m_branch_target_adder(
  .in_a   (ex_pc),
  .in_b   (ex_sextimm),

  .result (ex_pc_target)
);

/* m_branch_control : checks T/NT */
branch_control m_branch_control(
  .branch (ex_branch),
  .check  (ex_check),
  
  .taken  (ex_taken)
);

/* alu control : generates alu_func signal */
alu_control m_alu_control(
  .alu_op   (ex_aluop),
  .funct7   (ex_funct7),
  .funct3   (ex_funct3),

  .alu_func (ex_alu_func)
);

/* m_alu */

mux_3x1 m_mux_3x1_alusrc1(
  .select(ex_alusrc1),
  .in1(mem_regdata),
  .in2(wb_regdata),
  .in3(ex_readdata1),
  .out(ex_aluin1)
);

mux_3x1 m_mux_3x1_alusrc2(
  .select(ex_alusrc2),
  .in1(mem_regdata),
  .in2(wb_regdata),
  .in3(ex_readdata2),
  .out(ex_selected_data)
);

mux_2x1 m_mux_2x1_alu(
  .select(ex_alusrc),
  .in1(ex_selected_data),
  .in2(ex_sextimm),
  .out(ex_aluin2)
);

alu m_alu(
  .alu_func (ex_alu_func),
  .in_a     (ex_aluin1), 
  .in_b     (ex_aluin2), 

  .result   (ex_alu_result),
  .check    (ex_check)
);

mux_3x1 m_mux_3x1_exRegdata(
  .select(ex_lui),
  .in1(ex_alu_result),
  .in2(ex_sextimm),
  .in3(ex_pc_target),
  .out(ex_regdata)
);

forwarding m_forwarding(
  // TODO: implement forwarding unit & do wiring
  .ex_rs1 (ex_rs1),
  .ex_rs2 (ex_rs2),
  .mem_rd (mem_rd),
  .wb_rd (wb_rd),
  .mem_regwrite (mem_regwrite),
  .wb_regwrite (wb_regwrite),

  .alusrc1(ex_alusrc1),
  .alusrc2(ex_alusrc2)
);

/* forward to EX/MEM stage registers */
exmem_reg m_exmem_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .ex_pc          (ex_pc),
  .ex_pc_plus_4   (ex_pc_plus_4),
  .ex_pc_target   (ex_pc_target),
  .ex_branch      (ex_branch),
  .ex_taken       (ex_taken),
  .ex_jump        (ex_jump),
  .ex_memread     (ex_memread),
  .ex_memwrite    (ex_memwrite),
  .ex_memtoreg    (ex_memtoreg),
  .ex_regwrite    (ex_regwrite),
  .ex_alu_result  (ex_regdata),
  .ex_writedata   (ex_selected_data),
  .ex_funct3      (ex_funct3),
  .ex_rd          (ex_rd),
  .flush          (flush),
  
  .mem_pc         (mem_pc),
  .mem_pc_plus_4  (mem_pc_plus_4),
  .mem_pc_target  (mem_pc_target),
  .mem_branch     (mem_branch),
  .mem_taken      (mem_taken), 
  .mem_jump       (mem_jump),
  .mem_memread    (mem_memread),
  .mem_memwrite   (mem_memwrite),
  .mem_memtoreg   (mem_memtoreg),
  .mem_regwrite   (mem_regwrite),
  .mem_alu_result (mem_alu_result),
  .mem_writedata  (mem_writedata),
  .mem_funct3     (mem_funct3),
  .mem_rd         (mem_rd)
);


//////////////////////////////////////////////////////////////////////////////////
// Memory (MEM) 
//////////////////////////////////////////////////////////////////////////////////

mux_2x1 m_mux_2x1_branch(
  .select(mem_taken),
  .in1(mem_pc_plus_4),
  .in2(mem_pc_target),

  .out(mem_pc_result)
);

mux_4x1 m_mux_4x1_nextPC(
  .select(mem_jump),
  .in1(mem_pc_result),
  .in2(mem_pc_target),
  .in3(mem_alu_result),
  .in4(0),

  .out(mem_branch_next_pc)
);

/* m_data_memory : main memory module */
data_memory m_data_memory(
  .clk         (clk),
  .address     (mem_alu_result),
  .write_data  (mem_writedata),
  .mem_read    (mem_memread),
  .mem_write   (mem_memwrite),
  .maskmode    (mem_funct3[1:0]),
  .sext        (mem_funct3[2]),

  .read_data   (mem_readdata)
);

mux_2x1 m_mux_2x1_memData(
  .select(mem_memtoreg),
  .in1(mem_alu_result),
  .in2(mem_readdata),
  .out(mem_data)
);

mux_3x1 m_mux_3x1_memWriteData(
  .select(mem_jump),
  .in1(mem_data),
  .in2(mem_pc_plus_4),
  .in3(mem_pc_plus_4),
  .out(mem_regdata)
);

/* forward to MEM/WB stage registers */
memwb_reg m_memwb_reg(
  // TODO: Add flush or stall signal if it is needed
 .clk            (clk),
  .mem_pc_plus_4  (mem_pc_plus_4),
  .mem_jump       (mem_jump),
  .mem_memtoreg   (mem_memtoreg),
  .mem_regwrite   (mem_regwrite),
  .mem_readdata   (mem_readdata),
  .mem_alu_result (mem_alu_result),
  .mem_rd         (mem_rd),

  .wb_pc_plus_4   (wb_pc_plus_4),
  .wb_jump        (wb_jump),
  .wb_memtoreg    (wb_memtoreg),
  .wb_regwrite    (wb_regwrite),
  .wb_readdata    (wb_readdata),
  .wb_alu_result  (wb_alu_result),
  .wb_rd          (wb_rd)
);

//////////////////////////////////////////////////////////////////////////////////
// Write Back (WB) 
//////////////////////////////////////////////////////////////////////////////////

mux_2x1 m_mux_2x1_wbData(
  .select(wb_memtoreg),
  .in1(wb_alu_result),
  .in2(wb_readdata),
  .out(wb_data)
);

mux_3x1 m_mux_3x1_wbWriteData(
  .select(wb_jump),
  .in1(wb_data),
  .in2(wb_pc_plus_4),
  .in3(wb_pc_plus_4),
  .out(wb_regdata)
);

endmodule
