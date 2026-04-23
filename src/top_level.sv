

module top_level(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       sw9,
  input  logic       sw8,
  input  logic       sw7,
  input  logic       sw6,
  output logic [6:0] displayA,
  output logic [6:0] displayB,
  output logic [6:0] displayC,
  output logic [6:0] displayD
);

  logic [31:0] next_pc;
  logic [31:0] address;

  pc pc_inst(
    .clk(clk),
    .rst(~rst_n),
    .next_pc(next_pc),
    .pc_out(address)
  );

  logic [31:0] instr;

  instruction_memory imem_inst (
    .clk(clk),
    .address(address),
    .instruction(instr)
  );

  logic [6:0] funct7; assign funct7 = instr[31:25];
  logic [4:0] rs2;    assign rs2    = instr[24:20];
  logic [4:0] rs1;    assign rs1    = instr[19:15];
  logic [2:0] funct3; assign funct3 = instr[14:12];
  logic [4:0] rd;     assign rd     = instr[11:7];
  logic [6:0] opcode; assign opcode = instr[6:0];

  logic [31:0] imm_extended;
  logic [2:0] immsrc;

  imm_gen imm_gen_inst (
    .instruction(instr),
    .immsrc_type(immsrc),
    .immediate_out(imm_extended)
  );

  logic [3:0] ALU_op;
  logic       ALU_src;
  logic       reg_write;
  logic       mem_to_reg;
  logic       mem_write;
  logic       branch;
  logic       jump;
  logic [2:0] branch_type;

  control_unit control_inst (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_op(ALU_op),
    .alu_src(ALU_src),
    .reg_write(reg_write),
    .mem_to_reg(mem_to_reg),
    .mem_write(mem_write),
    .branch(branch),
    .jump(jump),
    .branch_type(branch_type),
    .immsrc_type(immsrc)
  );

  logic [31:0] rs1_data, rs2_data;
  logic [31:0] pc_plus_4; assign pc_plus_4 = address + 4;
  logic [31:0] data_wr;   assign data_wr = jump ? pc_plus_4 : (mem_to_reg ? mem_data : ALU_res);

  registers_unit regfile_inst (
    .clk(clk),
    .rst(~rst_n),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .ru_wr(reg_write),
    .data_wr(data_wr),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
  );

  logic [31:0] ALU_res;
  logic [31:0] ALU_A;
  logic [31:0] ALU_B;

  always_comb begin
    if (opcode == 7'b0110111)      // OPC_LUI
      ALU_A = 32'b0;
    else if (opcode == 7'b0010111) // OPC_AUIPC
      ALU_A = address;
    else
      ALU_A = rs1_data;
  end

  assign ALU_B = ALU_src ? imm_extended : rs2_data;

  alu alu_inst (
    .operand_a(ALU_A),
    .operand_b(ALU_B),
    .alu_op(ALU_op),
    .alu_result(ALU_res)
  );

  logic branch_taken;

  branch_unit branch_unit_inst (
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .branch_type(branch_type),
    .branch(branch),
    .branch_taken(branch_taken)
  );

  logic [31:0] pc_branch; assign pc_branch = address + imm_extended;
  logic        pc_src; assign pc_src = (branch_taken | jump);
  logic        is_jalr; assign is_jalr = (opcode == 7'b1100111);
  logic [31:0] jump_target; assign jump_target = is_jalr ? ALU_res : pc_branch;
  assign next_pc = pc_src ? jump_target : pc_plus_4;

  logic [31:0] mem_data;

  data_memory dmem_inst (
    .clk(clk),
    .address(ALU_res),
    .DMWR(rs2_data),
    .DMCTRL(funct3),
    .mem_write(mem_write),
    .Datard(mem_data)
  );

  logic [31:0] selected_value;
  always_comb begin
    case ({sw8, sw7, sw6})
      3'b000: selected_value = address;
      3'b001: selected_value = instr;
      3'b010: selected_value = rs1_data;
      3'b011: selected_value = rs2_data;
      3'b100: selected_value = imm_extended;
      3'b101: selected_value = ALU_res;
      3'b110: selected_value = mem_data;
      3'b111: selected_value = {27'b0, rd};
      default: selected_value = 32'b0;
    endcase
  end

  logic [15:0] value_to_display; assign value_to_display = sw9 ? selected_value[31:16] : selected_value[15:0];

  hex7seg display0(.val(value_to_display[3:0]),   .display(displayA));
  hex7seg display1(.val(value_to_display[7:4]),   .display(displayB));
  hex7seg display2(.val(value_to_display[11:8]),  .display(displayC));
  hex7seg display3(.val(value_to_display[15:12]), .display(displayD));

endmodule
