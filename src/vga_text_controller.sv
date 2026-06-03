module vga_text_controller (
    input logic clk_25mhz,
    input logic video_on,
    input logic [9:0] pixel_x,
    input logic [9:0] pixel_y,
    input logic [31:0] address,
    input logic [31:0] next_pc,
    input logic [31:0] instr,
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic [31:0] imm_extended,
    input logic [4:0] rs1,
    input logic [31:0] rs1_data,
    input logic [4:0] rs2,
    input logic [31:0] rs2_data,
    input logic [4:0] rd,
    input logic [31:0] ALU_A,
    input logic [31:0] ALU_B,
    input logic [31:0] ALU_res,
    input logic branch_taken,
    input logic jump,
    input logic [31:0] mem_data,
    input logic mem_write,
    input logic reg_write,
    input logic ALU_src,
    input logic mem_to_reg,
    input logic [31:0] data_wr,
    input logic [31:0] reg_file [0:31],
    input logic [31:0] data_mem [0:127],
    output logic [7:0] VGA_R,
    output logic [7:0] VGA_G,
    output logic [7:0] VGA_B
);
    logic [6:0] col;
    logic [4:0] row;
    assign col = pixel_x[9:3];
    assign row = pixel_y[9:4];
    logic [7:0] char_code;
    logic [11:0] rom_addr;
    logic [7:0] font_word;
    font_rom font_unit (
        .clk(clk_25mhz),
        .addr(rom_addr),
        .data(font_word)
    );
    assign rom_addr = {char_code[7:0], pixel_y[3:0]};
    logic [2:0] pixel_x_d1;
    logic       video_on_d1, video_on_d2;
    always_ff @(posedge clk_25mhz) begin
        pixel_x_d1  <= pixel_x[2:0];
        video_on_d1 <= video_on;
        video_on_d2 <= video_on_d1;
    end
    logic font_bit;
    assign font_bit = font_word[7 - pixel_x_d1];
    function automatic [7:0] hex2ascii(input [3:0] hex_val);
        begin
            if (hex_val < 10)
                hex2ascii = 8'h30 + 8'(hex_val);
            else
                hex2ascii = 8'h41 + 8'(hex_val - 10);
        end
    endfunction
    function automatic [7:0] hex32_char(input [31:0] val, input [3:0] idx);
        logic [3:0] nibble;
        begin
            case (idx)
                4'd0: nibble = val[31:28];
                4'd1: nibble = val[27:24];
                4'd2: nibble = val[23:20];
                4'd3: nibble = val[19:16];
                4'd4: nibble = val[15:12];
                4'd5: nibble = val[11:8];
                4'd6: nibble = val[7:4];
                4'd7: nibble = val[3:0];
                default: nibble = 4'h0;
            endcase
            hex32_char = hex2ascii(nibble);
        end
    endfunction
    function automatic [7:0] hex8_char(input [7:0] val, input bit idx);
        logic [3:0] nibble;
        begin
            if (idx == 0) nibble = val[7:4];
            else          nibble = val[3:0];
            hex8_char = hex2ascii(nibble);
        end
    endfunction
    function automatic [7:0] hex7_char(input [6:0] val, input bit idx);
        logic [3:0] nibble;
        begin
            if (idx == 0) nibble = {1'b0, val[6:4]};
            else          nibble = val[3:0];
            hex7_char = hex2ascii(nibble);
        end
    endfunction
    function automatic [7:0] hex5_char(input [4:0] val, input bit idx);
        logic [3:0] nibble;
        begin
            if (idx == 0) nibble = {3'b000, val[4]};
            else          nibble = val[3:0];
            hex5_char = hex2ascii(nibble);
        end
    endfunction
    function automatic [7:0] hex3_char(input [2:0] val);
        hex3_char = hex2ascii({1'b0, val});
    endfunction
    function automatic [7:0] bit_char(input b);
        bit_char = b ? 8'h31 : 8'h30;
    endfunction
    always_comb begin
        char_code = 8'h20;
        case (row)
            5'd0: begin
                if (col <= 4) begin
                    case (col)
                        0: char_code = "A"; 1: char_code = "D"; 2: char_code = "D"; 3: char_code = "R"; 4: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 6 && col <= 13) begin
                    char_code = hex32_char(address, 4'(col - 6));
                end
                if (col >= 40 && col <= 47) begin
                    case (col - 40)
                        0: char_code = "N"; 1: char_code = "E"; 2: char_code = "X"; 3: char_code = "T"; 4: char_code = "_"; 5: char_code = "P"; 6: char_code = "C"; 7: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 49 && col <= 56) begin
                    char_code = hex32_char(next_pc, 4'(col - 49));
                end
            end
            5'd1: begin
                if (col <= 5) begin
                    case (col)
                        0: char_code = "I"; 1: char_code = "N"; 2: char_code = "S"; 3: char_code = "T"; 4: char_code = "R"; 5: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 7 && col <= 14) begin
                    char_code = hex32_char(instr, 4'(col - 7));
                end
                if (col >= 40 && col <= 46) begin
                    case (col - 40)
                        0: char_code = "O"; 1: char_code = "P"; 2: char_code = "C"; 3: char_code = "O"; 4: char_code = "D"; 5: char_code = "E"; 6: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 48 && col <= 49) begin
                    char_code = hex7_char(opcode, 1'(col - 48));
                end
                if (col >= 51 && col <= 57) begin
                    case (col - 51)
                        0: char_code = "F"; 1: char_code = "U"; 2: char_code = "N"; 3: char_code = "C"; 4: char_code = "T"; 5: char_code = "3"; 6: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col == 59) begin
                    char_code = hex3_char(funct3);
                end
                if (col >= 61 && col <= 67) begin
                    case (col - 61)
                        0: char_code = "F"; 1: char_code = "U"; 2: char_code = "N"; 3: char_code = "C"; 4: char_code = "T"; 5: char_code = "7"; 6: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 69 && col <= 70) begin
                    char_code = hex7_char(funct7, 1'(col - 69));
                end
            end
            5'd2: begin
                if (col <= 3) begin
                    case (col)
                        0: char_code = "I"; 1: char_code = "M"; 2: char_code = "M"; 3: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 5 && col <= 12) begin
                    char_code = hex32_char(imm_extended, 4'(col - 5));
                end
                if (col >= 40 && col <= 43) begin
                    case (col - 40)
                        0: char_code = "R"; 1: char_code = "S"; 2: char_code = "1"; 3: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 45 && col <= 46) begin
                    char_code = hex5_char(rs1, 1'(col - 45));
                end
                if (col >= 48 && col <= 56) begin
                    case (col - 48)
                        0: char_code = "R"; 1: char_code = "S"; 2: char_code = "1"; 3: char_code = "_"; 4: char_code = "D"; 5: char_code = "A"; 6: char_code = "T"; 7: char_code = "A"; 8: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 58 && col <= 65) begin
                    char_code = hex32_char(rs1_data, 4'(col - 58));
                end
            end
            5'd3: begin
                if (col <= 3) begin
                    case (col)
                        0: char_code = "R"; 1: char_code = "S"; 2: char_code = "2"; 3: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 5 && col <= 6) begin
                    char_code = hex5_char(rs2, 1'(col - 5));
                end
                if (col >= 8 && col <= 16) begin
                    case (col - 8)
                        0: char_code = "R"; 1: char_code = "S"; 2: char_code = "2"; 3: char_code = "_"; 4: char_code = "D"; 5: char_code = "A"; 6: char_code = "T"; 7: char_code = "A"; 8: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 18 && col <= 25) begin
                    char_code = hex32_char(rs2_data, 4'(col - 18));
                end
                if (col >= 40 && col <= 42) begin
                    case (col - 40)
                        0: char_code = "R"; 1: char_code = "D"; 2: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 44 && col <= 45) begin
                    char_code = hex5_char(rd, 1'(col - 44));
                end
                if (col >= 47 && col <= 56) begin
                    case (col - 47)
                        0: char_code = "R"; 1: char_code = "E"; 2: char_code = "G"; 3: char_code = "_"; 4: char_code = "W"; 5: char_code = "R"; 6: char_code = "I"; 7: char_code = "T"; 8: char_code = "E"; 9: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col == 58) begin
                    char_code = bit_char(reg_write);
                end
            end
            5'd4: begin
                if (col <= 5) begin
                    case (col)
                        0: char_code = "A"; 1: char_code = "L"; 2: char_code = "U"; 3: char_code = "_"; 4: char_code = "A"; 5: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 7 && col <= 14) begin
                    char_code = hex32_char(ALU_A, 4'(col - 7));
                end
                if (col >= 40 && col <= 45) begin
                    case (col - 40)
                        0: char_code = "A"; 1: char_code = "L"; 2: char_code = "U"; 3: char_code = "_"; 4: char_code = "B"; 5: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 47 && col <= 54) begin
                    char_code = hex32_char(ALU_B, 4'(col - 47));
                end
            end
            5'd5: begin
                if (col <= 7) begin
                    case (col)
                        0: char_code = "A"; 1: char_code = "L"; 2: char_code = "U"; 3: char_code = "_"; 4: char_code = "R"; 5: char_code = "E"; 6: char_code = "S"; 7: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 9 && col <= 16) begin
                    char_code = hex32_char(ALU_res, 4'(col - 9));
                end
                if (col >= 40 && col <= 47) begin
                    case (col - 40)
                        0: char_code = "A"; 1: char_code = "L"; 2: char_code = "U"; 3: char_code = "_"; 4: char_code = "S"; 5: char_code = "R"; 6: char_code = "C"; 7: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col == 49) begin
                    char_code = bit_char(ALU_src);
                end
            end
            5'd6: begin
                if (col <= 8) begin
                    case (col)
                        0: char_code = "M"; 1: char_code = "E"; 2: char_code = "M"; 3: char_code = "_"; 4: char_code = "D"; 5: char_code = "A"; 6: char_code = "T"; 7: char_code = "A"; 8: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 10 && col <= 17) begin
                    char_code = hex32_char(mem_data, 4'(col - 10));
                end
                if (col >= 40 && col <= 47) begin
                    case (col - 40)
                        0: char_code = "D"; 1: char_code = "A"; 2: char_code = "T"; 3: char_code = "A"; 4: char_code = "_"; 5: char_code = "W"; 6: char_code = "R"; 7: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col >= 49 && col <= 56) begin
                    char_code = hex32_char(data_wr, 4'(col - 49));
                end
            end
            5'd7: begin
                if (col <= 9) begin
                    case (col)
                        0: char_code = "M"; 1: char_code = "E"; 2: char_code = "M"; 3: char_code = "_"; 4: char_code = "W"; 5: char_code = "R"; 6: char_code = "I"; 7: char_code = "T"; 8: char_code = "E"; 9: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col == 11) begin
                    char_code = bit_char(mem_write);
                end
                if (col >= 40 && col <= 50) begin
                    case (col - 40)
                        0: char_code = "M"; 1: char_code = "E"; 2: char_code = "M"; 3: char_code = "_"; 4: char_code = "T"; 5: char_code = "O"; 6: char_code = "_"; 7: char_code = "R"; 8: char_code = "E"; 9: char_code = "G"; 10: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col == 52) begin
                    char_code = bit_char(mem_to_reg);
                end
            end
            5'd8: begin
                if (col <= 12) begin
                    case (col)
                        0: char_code = "B"; 1: char_code = "R"; 2: char_code = "A"; 3: char_code = "N"; 4: char_code = "C"; 5: char_code = "H"; 6: char_code = "_"; 7: char_code = "T"; 8: char_code = "A"; 9: char_code = "K"; 10: char_code = "E"; 11: char_code = "N"; 12: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col == 14) begin
                    char_code = bit_char(branch_taken);
                end
                if (col >= 40 && col <= 44) begin
                    case (col - 40)
                        0: char_code = "J"; 1: char_code = "U"; 2: char_code = "M"; 3: char_code = "P"; 4: char_code = ":"; default: char_code = " ";
                    endcase
                end else if (col == 46) begin
                    char_code = bit_char(jump);
                end
            end
            5'd10, 5'd11, 5'd12, 5'd13, 5'd14, 5'd15, 5'd16, 5'd17,
            5'd18, 5'd19, 5'd20, 5'd21, 5'd22, 5'd23, 5'd24, 5'd25: begin
                logic [4:0] reg_row_idx;
                logic [4:0] left_reg, right_reg;
                reg_row_idx = row - 10;
                left_reg = reg_row_idx * 2;
                right_reg = reg_row_idx * 2 + 1;
                if (col <= 2) begin
                    case (col)
                        0: char_code = "x";
                        1: char_code = hex5_char(left_reg, 1'b0);
                        2: char_code = hex5_char(left_reg, 1'b1);
                    endcase
                end else if (col == 3) begin
                    char_code = ":";
                end else if (col >= 4 && col <= 11) begin
                    char_code = hex32_char(reg_file[left_reg], 4'(col - 4));
                end else if (col >= 14 && col <= 16) begin
                    case (col - 14)
                        0: char_code = "x";
                        1: char_code = hex5_char(right_reg, 1'b0);
                        2: char_code = hex5_char(right_reg, 1'b1);
                    endcase
                end else if (col == 17) begin
                    char_code = ":";
                end else if (col >= 18 && col <= 25) begin
                    char_code = hex32_char(reg_file[right_reg], 4'(col - 18));
                end
            end
            5'd26, 5'd27, 5'd28, 5'd29: begin
                logic [4:0] mem_row_idx;
                logic [6:0] base_addr;
                mem_row_idx = row - 26;
                base_addr = 7'd112 + mem_row_idx * 16;
                if (col <= 7) begin
                    case (col)
                        0: char_code = "D"; 1: char_code = "A"; 2: char_code = "T"; 3: char_code = "A"; 
                        4: char_code = "["; 5: char_code = hex8_char({1'b0, base_addr}, 1'b0);
                        6: char_code = hex8_char({1'b0, base_addr}, 1'b1); 7: char_code = "]";
                    endcase
                end else if (col == 8) begin
                    char_code = ":";
                end else if (col >= 10 && col <= 57) begin
                    logic [3:0] byte_idx;
                    logic [6:0] mem_addr;
                    logic [31:0] mem_word;
                    logic [1:0] byte_sel;
                    byte_idx = (col - 10) / 3;
                    mem_addr = base_addr + byte_idx;
                    mem_word = data_mem[mem_addr >> 2];
                    byte_sel = mem_addr[1:0];
                    if ((col - 10) % 3 < 2) begin
                        logic [7:0] byte_val;
                        case (byte_sel)
                            2'b00: byte_val = mem_word[7:0];
                            2'b01: byte_val = mem_word[15:8];
                            2'b10: byte_val = mem_word[23:16];
                            2'b11: byte_val = mem_word[31:24];
                        endcase
                        char_code = hex8_char(byte_val, 1'((col - 10) % 3));
                    end else begin
                        char_code = " ";
                    end
                end
            end
            default: char_code = 8'h20;
        endcase
    end
    always_ff @(posedge clk_25mhz) begin
        if (video_on_d2) begin
            if (font_bit) begin
                VGA_R <= 8'h00;
                VGA_G <= 8'hFF;
                VGA_B <= 8'h00;
            end else begin
                VGA_R <= 8'h00;
                VGA_G <= 8'h00;
                VGA_B <= 8'h00;
            end
        end else begin
            VGA_R <= 8'h00;
            VGA_G <= 8'h00;
            VGA_B <= 8'h00;
        end
    end
endmodule
