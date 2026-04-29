

module top_level(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       CLOCK_50,
  output logic [7:0] VGA_R,
  output logic [7:0] VGA_G,
  output logic [7:0] VGA_B,
  output logic       VGA_HS,
  output logic       VGA_VS,
  output logic       VGA_CLK,
  output logic       VGA_BLANK_N,
  output logic       VGA_SYNC_N
);

  wire cpu_clk;
  logic clk_q1, clk_q2;
  always_ff @(posedge CLOCK_50) begin
    clk_q1 <= clk;
    clk_q2 <= clk_q1;
  end
  assign cpu_clk = clk_q1 & ~clk_q2;

  logic [31:0] next_pc;
  logic [31:0] address;

  pc pc_inst(
    .clk(cpu_clk),
    .rst(~rst_n),
    .next_pc(next_pc),
    .pc_out(address)
  );

  logic [31:0] instr;

  instruction_memory imem_inst (
    .clk(cpu_clk),
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
    .clk(cpu_clk),
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
    .clk(cpu_clk),
    .address(ALU_res),
    .DMWR(rs2_data),
    .DMCTRL(funct3),
    .mem_write(mem_write),
    .Datard(mem_data)
  );

  logic clk_25mhz;
  always_ff @(posedge CLOCK_50 or negedge rst_n) begin
    if (!rst_n)
      clk_25mhz <= 1'b0;
    else
      clk_25mhz <= ~clk_25mhz;
  end

  logic video_on;
  logic [9:0] pixel_x, pixel_y;

  assign VGA_CLK = clk_25mhz;
  assign VGA_SYNC_N = 1'b0;
  assign VGA_BLANK_N = video_on;

  vga_sync vga_sync_inst (
    .clk_25mhz(clk_25mhz),
    .rst_n(rst_n),
    .hsync(VGA_HS),
    .vsync(VGA_VS),
    .video_on(video_on),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y)
  );

  vga_text_controller vga_text_controller_inst (
    .clk_25mhz(clk_25mhz),
    .video_on(video_on),
    .pixel_x(pixel_x),
    .pixel_y(pixel_y),
    .address(address),
    .next_pc(next_pc),
    .instr(instr),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .imm_extended(imm_extended),
    .rs1(rs1),
    .rs1_data(rs1_data),
    .rs2(rs2),
    .rs2_data(rs2_data),
    .rd(rd),
    .ALU_A(ALU_A),
    .ALU_B(ALU_B),
    .ALU_res(ALU_res),
    .branch_taken(branch_taken),
    .jump(jump),
    .mem_data(mem_data),
    .mem_write(mem_write),
    .reg_write(reg_write),
    .ALU_src(ALU_src),
    .mem_to_reg(mem_to_reg),
    .data_wr(data_wr),
    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B)
  );

endmodule
