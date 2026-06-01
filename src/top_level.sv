import rv_opcodes_pkg::*;

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

  localparam bit ENABLE_VGA = 1'b1;

  wire cpu_clk;
  logic clk_q1, clk_q2;
  always_ff @(posedge CLOCK_50) begin
    clk_q1 <= clk;
    clk_q2 <= clk_q1;
  end
  assign cpu_clk = clk_q1 & ~clk_q2;

  logic        stall;
  logic        flush;
  logic [31:0] flush_target;

  logic [31:0] pc_out;
  logic [31:0] pc_plus_4_if;
  logic [31:0] next_pc;
  logic        pc_write;

  assign pc_plus_4_if = pc_out + 32'd4;
  assign pc_write     = !stall;
  assign next_pc      = flush ? flush_target : pc_plus_4_if;

  pc pc_inst (
    .clk(cpu_clk),
    .rst(~rst_n),
    .pc_write(pc_write),
    .next_pc(next_pc),
    .pc_out(pc_out)
  );

  logic [31:0] instr_if;

  instruction_memory imem_inst (
    .clk(cpu_clk),
    .address(pc_out),
    .instruction(instr_if)
  );

  logic [31:0] if_id_pc;
  logic [31:0] if_id_pc_plus_4;
  logic [31:0] if_id_instr;

  always_ff @(posedge cpu_clk or negedge rst_n) begin
    if (!rst_n) begin
      if_id_pc        <= 32'b0;
      if_id_pc_plus_4 <= 32'b0;
      if_id_instr     <= 32'h00000013;
    end else if (flush) begin
      if_id_pc        <= 32'b0;
      if_id_pc_plus_4 <= 32'b0;
      if_id_instr     <= 32'h00000013;
    end else if (!stall) begin
      if_id_pc        <= pc_out;
      if_id_pc_plus_4 <= pc_plus_4_if;
      if_id_instr     <= instr_if;
    end
  end

  logic [6:0] if_id_opcode;
  logic [4:0] if_id_rd;
  logic [2:0] if_id_funct3;
  logic [6:0] if_id_funct7;
  logic [4:0] if_id_rs1;
  logic [4:0] if_id_rs2;

  assign if_id_opcode = if_id_instr[6:0];
  assign if_id_rd     = if_id_instr[11:7];
  assign if_id_funct3 = if_id_instr[14:12];
  assign if_id_funct7 = if_id_instr[31:25];
  assign if_id_rs1    = if_id_instr[19:15];
  assign if_id_rs2    = if_id_instr[24:20];

  logic [3:0] ctrl_alu_op;
  logic       ctrl_alu_src;
  logic       ctrl_reg_write;
  logic       ctrl_mem_to_reg;
  logic       ctrl_mem_write;
  logic       ctrl_branch;
  logic       ctrl_jump;
  logic [2:0] ctrl_branch_type;
  logic [2:0] ctrl_immsrc;

  control_unit control_inst (
    .opcode(if_id_opcode),
    .funct3(if_id_funct3),
    .funct7(if_id_funct7),
    .alu_op(ctrl_alu_op),
    .alu_src(ctrl_alu_src),
    .reg_write(ctrl_reg_write),
    .mem_to_reg(ctrl_mem_to_reg),
    .mem_write(ctrl_mem_write),
    .branch(ctrl_branch),
    .jump(ctrl_jump),
    .branch_type(ctrl_branch_type),
    .immsrc_type(ctrl_immsrc)
  );

  logic [31:0] imm_extended_id;

  imm_gen imm_gen_inst (
    .instruction(if_id_instr),
    .immsrc_type(ctrl_immsrc),
    .immediate_out(imm_extended_id)
  );

  logic [4:0]  wb_rd;
  logic        wb_reg_write;
  logic [31:0] wb_data;

  logic [31:0] rs1_data_id, rs2_data_id;
  logic [31:0] reg_file [0:31];

  registers_unit regfile_inst (
    .clk(cpu_clk),
    .rst(~rst_n),
    .rs1(if_id_rs1),
    .rs2(if_id_rs2),
    .rd(wb_rd),
    .ru_wr(wb_reg_write),
    .data_wr(wb_data),
    .rs1_data(rs1_data_id),
    .rs2_data(rs2_data_id),
    .registers(reg_file)
  );

  logic [31:0] id_ex_pc;
  logic [31:0] id_ex_pc_plus_4;
  logic [31:0] id_ex_rs1_data;
  logic [31:0] id_ex_rs2_data;
  logic [31:0] id_ex_imm;
  logic [4:0]  id_ex_rs1_addr;
  logic [4:0]  id_ex_rs2_addr;
  logic [4:0]  id_ex_rd_addr;
  logic [6:0]  id_ex_opcode;
  logic [2:0]  id_ex_funct3;
  logic [3:0]  id_ex_alu_op;
  logic        id_ex_alu_src;
  logic        id_ex_branch;
  logic [2:0]  id_ex_branch_type;
  logic        id_ex_jump;
  logic        id_ex_mem_write;
  logic        id_ex_mem_to_reg;
  logic        id_ex_reg_write;

  always_ff @(posedge cpu_clk or negedge rst_n) begin
    if (!rst_n) begin
      id_ex_pc          <= 32'b0;
      id_ex_pc_plus_4   <= 32'b0;
      id_ex_rs1_data    <= 32'b0;
      id_ex_rs2_data    <= 32'b0;
      id_ex_imm         <= 32'b0;
      id_ex_rs1_addr    <= 5'b0;
      id_ex_rs2_addr    <= 5'b0;
      id_ex_rd_addr     <= 5'b0;
      id_ex_opcode      <= 7'b0;
      id_ex_funct3      <= 3'b0;
      id_ex_alu_op      <= 4'b0;
      id_ex_alu_src     <= 1'b0;
      id_ex_branch      <= 1'b0;
      id_ex_branch_type <= 3'b0;
      id_ex_jump        <= 1'b0;
      id_ex_mem_write   <= 1'b0;
      id_ex_mem_to_reg  <= 1'b0;
      id_ex_reg_write   <= 1'b0;
    end else if (flush || stall) begin
      id_ex_pc          <= 32'b0;
      id_ex_pc_plus_4   <= 32'b0;
      id_ex_rs1_data    <= 32'b0;
      id_ex_rs2_data    <= 32'b0;
      id_ex_imm         <= 32'b0;
      id_ex_rs1_addr    <= 5'b0;
      id_ex_rs2_addr    <= 5'b0;
      id_ex_rd_addr     <= 5'b0;
      id_ex_opcode      <= 7'b0;
      id_ex_funct3      <= 3'b0;
      id_ex_alu_op      <= 4'b0;
      id_ex_alu_src     <= 1'b0;
      id_ex_branch      <= 1'b0;
      id_ex_branch_type <= 3'b0;
      id_ex_jump        <= 1'b0;
      id_ex_mem_write   <= 1'b0;
      id_ex_mem_to_reg  <= 1'b0;
      id_ex_reg_write   <= 1'b0;
    end else begin
      id_ex_pc          <= if_id_pc;
      id_ex_pc_plus_4   <= if_id_pc_plus_4;
      id_ex_rs1_data    <= rs1_data_id;
      id_ex_rs2_data    <= rs2_data_id;
      id_ex_imm         <= imm_extended_id;
      id_ex_rs1_addr    <= if_id_rs1;
      id_ex_rs2_addr    <= if_id_rs2;
      id_ex_rd_addr     <= if_id_rd;
      id_ex_opcode      <= if_id_opcode;
      id_ex_funct3      <= if_id_funct3;
      id_ex_alu_op      <= ctrl_alu_op;
      id_ex_alu_src     <= ctrl_alu_src;
      id_ex_branch      <= ctrl_branch;
      id_ex_branch_type <= ctrl_branch_type;
      id_ex_jump        <= ctrl_jump;
      id_ex_mem_write   <= ctrl_mem_write;
      id_ex_mem_to_reg  <= ctrl_mem_to_reg;
      id_ex_reg_write   <= ctrl_reg_write;
    end
  end

  hazard_detection_unit hdu_inst (
    .if_id_rs1(if_id_rs1),
    .if_id_rs2(if_id_rs2),
    .id_ex_rd(id_ex_rd_addr),
    .id_ex_mem_to_reg(id_ex_mem_to_reg),
    .stall(stall)
  );

  logic [1:0] forward_a, forward_b;

  logic [4:0]  ex_mem_rd_addr;
  logic        ex_mem_reg_write;
  logic [4:0]  mem_wb_rd_addr;
  logic        mem_wb_reg_write;

  forwarding_unit fwd_inst (
    .id_ex_rs1(id_ex_rs1_addr),
    .id_ex_rs2(id_ex_rs2_addr),
    .ex_mem_rd(ex_mem_rd_addr),
    .ex_mem_reg_write(ex_mem_reg_write),
    .mem_wb_rd(mem_wb_rd_addr),
    .mem_wb_reg_write(mem_wb_reg_write),
    .forward_a(forward_a),
    .forward_b(forward_b)
  );

  logic [31:0] forwarded_rs1, forwarded_rs2;
  logic [31:0] ex_mem_fwd_data;

  always_comb begin
    case (forward_a)
      2'b10:   forwarded_rs1 = ex_mem_fwd_data;
      2'b01:   forwarded_rs1 = wb_data;
      default: forwarded_rs1 = id_ex_rs1_data;
    endcase
  end

  always_comb begin
    case (forward_b)
      2'b10:   forwarded_rs2 = ex_mem_fwd_data;
      2'b01:   forwarded_rs2 = wb_data;
      default: forwarded_rs2 = id_ex_rs2_data;
    endcase
  end

  logic [31:0] alu_a, alu_b;

  always_comb begin
    if (id_ex_opcode == OPC_LUI)
      alu_a = 32'b0;
    else if (id_ex_opcode == OPC_AUIPC)
      alu_a = id_ex_pc;
    else
      alu_a = forwarded_rs1;
  end

  assign alu_b = id_ex_alu_src ? id_ex_imm : forwarded_rs2;

  logic [31:0] alu_result;

  alu alu_inst (
    .operand_a(alu_a),
    .operand_b(alu_b),
    .alu_op(id_ex_alu_op),
    .alu_result(alu_result)
  );

  logic branch_taken;

  branch_unit branch_unit_inst (
    .rs1_data(forwarded_rs1),
    .rs2_data(forwarded_rs2),
    .branch_type(id_ex_branch_type),
    .branch(id_ex_branch),
    .branch_taken(branch_taken)
  );

  logic [31:0] branch_target;
  logic        is_jalr;

  assign branch_target = id_ex_pc + id_ex_imm;
  assign is_jalr       = (id_ex_opcode == OPC_JALR);

  assign flush        = branch_taken | id_ex_jump;
  assign flush_target = is_jalr ? alu_result : branch_target;

  logic [31:0] ex_mem_alu_result;
  logic [31:0] ex_mem_pc_plus_4;
  logic [31:0] ex_mem_rs2_data;
  logic [2:0]  ex_mem_funct3;
  logic        ex_mem_mem_write;
  logic        ex_mem_mem_to_reg;
  logic        ex_mem_jump;

  always_ff @(posedge cpu_clk or negedge rst_n) begin
    if (!rst_n) begin
      ex_mem_alu_result <= 32'b0;
      ex_mem_pc_plus_4  <= 32'b0;
      ex_mem_rs2_data   <= 32'b0;
      ex_mem_rd_addr    <= 5'b0;
      ex_mem_funct3     <= 3'b0;
      ex_mem_mem_write  <= 1'b0;
      ex_mem_mem_to_reg <= 1'b0;
      ex_mem_reg_write  <= 1'b0;
      ex_mem_jump       <= 1'b0;
    end else begin
      ex_mem_alu_result <= alu_result;
      ex_mem_pc_plus_4  <= id_ex_pc_plus_4;
      ex_mem_rs2_data   <= forwarded_rs2;
      ex_mem_rd_addr    <= id_ex_rd_addr;
      ex_mem_funct3     <= id_ex_funct3;
      ex_mem_mem_write  <= id_ex_mem_write;
      ex_mem_mem_to_reg <= id_ex_mem_to_reg;
      ex_mem_reg_write  <= id_ex_reg_write;
      ex_mem_jump       <= id_ex_jump;
    end
  end

  assign ex_mem_fwd_data = ex_mem_jump ? ex_mem_pc_plus_4 : ex_mem_alu_result;

  logic [31:0] mem_data;
  logic [31:0] data_mem [0:127];

  data_memory dmem_inst (
    .clk(cpu_clk),
    .address(ex_mem_alu_result),
    .DMWR(ex_mem_rs2_data),
    .DMCTRL(ex_mem_funct3),
    .mem_write(ex_mem_mem_write),
    .Datard(mem_data),
    .memory(data_mem)
  );

  logic [31:0] mem_wb_mem_data;
  logic [31:0] mem_wb_alu_result;
  logic [31:0] mem_wb_pc_plus_4;
  logic        mem_wb_mem_to_reg;
  logic        mem_wb_jump;

  always_ff @(posedge cpu_clk or negedge rst_n) begin
    if (!rst_n) begin
      mem_wb_mem_data   <= 32'b0;
      mem_wb_alu_result <= 32'b0;
      mem_wb_pc_plus_4  <= 32'b0;
      mem_wb_rd_addr    <= 5'b0;
      mem_wb_reg_write  <= 1'b0;
      mem_wb_mem_to_reg <= 1'b0;
      mem_wb_jump       <= 1'b0;
    end else begin
      mem_wb_mem_data   <= mem_data;
      mem_wb_alu_result <= ex_mem_alu_result;
      mem_wb_pc_plus_4  <= ex_mem_pc_plus_4;
      mem_wb_rd_addr    <= ex_mem_rd_addr;
      mem_wb_reg_write  <= ex_mem_reg_write;
      mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
      mem_wb_jump       <= ex_mem_jump;
    end
  end

  assign wb_rd       = mem_wb_rd_addr;
  assign wb_reg_write = mem_wb_reg_write;
  assign wb_data     = mem_wb_jump      ? mem_wb_pc_plus_4 :
                       mem_wb_mem_to_reg ? mem_wb_mem_data  :
                                           mem_wb_alu_result;

  logic [31:0] reg_file_vga [0:31];
  logic [31:0] data_mem_vga [0:127];

  generate
    if (ENABLE_VGA) begin : gen_vga
      logic clk_25mhz;
      logic video_on;
      logic [9:0] pixel_x, pixel_y;

      always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n)
          clk_25mhz <= 1'b0;
        else
          clk_25mhz <= ~clk_25mhz;
      end

      assign VGA_CLK     = clk_25mhz;
      assign VGA_SYNC_N  = 1'b0;
      assign VGA_BLANK_N = video_on;

      always_ff @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
          reg_file_vga <= '{default: 32'h0};
          data_mem_vga <= '{default: 32'h0};
        end else begin
          reg_file_vga <= reg_file;
          data_mem_vga <= data_mem;
        end
      end

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
        .address(pc_out),
        .next_pc(next_pc),
        .instr(if_id_instr),
        .opcode(if_id_opcode),
        .funct3(if_id_funct3),
        .funct7(if_id_funct7),
        .imm_extended(imm_extended_id),
        .rs1(if_id_rs1),
        .rs1_data(rs1_data_id),
        .rs2(if_id_rs2),
        .rs2_data(rs2_data_id),
        .rd(if_id_rd),
        .ALU_A(alu_a),
        .ALU_B(alu_b),
        .ALU_res(alu_result),
        .branch_taken(branch_taken),
        .jump(id_ex_jump),
        .mem_data(mem_data),
        .mem_write(ex_mem_mem_write),
        .reg_write(mem_wb_reg_write),
        .ALU_src(id_ex_alu_src),
        .mem_to_reg(mem_wb_mem_to_reg),
        .data_wr(wb_data),
        .reg_file(reg_file_vga),
        .data_mem(data_mem_vga),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B)
      );
    end else begin : gen_vga_off
      assign VGA_R       = 8'h00;
      assign VGA_G       = 8'h00;
      assign VGA_B       = 8'h00;
      assign VGA_HS      = 1'b0;
      assign VGA_VS      = 1'b0;
      assign VGA_CLK     = 1'b0;
      assign VGA_BLANK_N = 1'b0;
      assign VGA_SYNC_N  = 1'b0;
    end
  endgenerate

endmodule
