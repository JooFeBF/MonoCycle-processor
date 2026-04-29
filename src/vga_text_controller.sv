/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */
module vga_text_controller (
    input logic clk_25mhz,
    input logic video_on,
    input logic [9:0] pixel_x,
    input logic [9:0] pixel_y,
    // RISC-V states
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
    
    // Outputs
    output logic [7:0] VGA_R,
    output logic [7:0] VGA_G,
    output logic [7:0] VGA_B
);

    logic [6:0] col;
    logic [5:0] row;
    assign col = pixel_x[9:3];
    assign row = pixel_y[9:4];

    logic [7:0] char_code;
    logic [10:0] rom_addr;
    logic [7:0] font_word;

    // Instance of font rom
    font_rom font_unit (
        .clk(clk_25mhz),
        .addr(rom_addr),
        .data(font_word)
    );

    // Font ROM address: char_code * 16 + row index inside character
    assign rom_addr = {char_code[6:0], pixel_y[3:0]};

    logic font_bit;
    assign font_bit = font_word[~pixel_x[2:0]]; // bits are reversed in typical font roms or we can use 7 - pixel_x[2:0]

    // Helper functions
    function automatic [7:0] hex2ascii(input [3:0] hex_val);
        begin
            if (hex_val < 10)
                hex2ascii = 8'h30 + 8'(hex_val); // '0' - '9'
            else
                hex2ascii = 8'h41 + 8'(hex_val - 10); // 'A' - 'F'
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
        char_code = 8'h20; // Default to space
        
        case (row)
            6'd2: begin
                // PC Address:  
                if (col >= 5 && col <= 15) begin
                    case (col - 5)
                        0: char_code = "P"; 1: char_code = "C"; 2: char_code = " "; 3: char_code = "A"; 4: char_code = "d"; 5: char_code = "d"; 6: char_code = "r"; 7: char_code = "e"; 8: char_code = "s"; 9: char_code = "s"; 10: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 17 && col <= 24) begin
                    char_code = hex32_char(address, 4'(col - 17));
                end
            end
            
            6'd3: begin
                if (col >= 5 && col <= 16) begin
                    case (col - 5)
                        0: char_code = "I"; 1: char_code = "n"; 2: char_code = "s"; 3: char_code = "t"; 4: char_code = "r"; 5: char_code = "u"; 6: char_code = "c"; 7: char_code = "t"; 8: char_code = "i"; 9: char_code = "o"; 10: char_code = "n"; 11: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 18 && col <= 25) begin
                    char_code = hex32_char(instr, 4'(col - 18));
                end
            end
            
            6'd5: begin
                if (col >= 5 && col <= 11) begin
                    case (col - 5)
                        0: char_code = "O"; 1: char_code = "p"; 2: char_code = "c"; 3: char_code = "o"; 4: char_code = "d"; 5: char_code = "e"; 6: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 13 && col <= 14) begin
                    char_code = hex7_char(opcode, 1'(col - 13));
                end
                
                if (col >= 20 && col <= 26) begin
                    case (col - 20)
                        0: char_code = "F"; 1: char_code = "u"; 2: char_code = "n"; 3: char_code = "c"; 4: char_code = "t"; 5: char_code = "3"; 6: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col == 28) begin
                    char_code = hex3_char(funct3);
                end
                
                if (col >= 35 && col <= 41) begin
                    case (col - 35)
                        0: char_code = "F"; 1: char_code = "u"; 2: char_code = "n"; 3: char_code = "c"; 4: char_code = "t"; 5: char_code = "7"; 6: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 43 && col <= 44) begin
                    char_code = hex7_char(funct7, 1'(col - 43));
                end
            end
            
            6'd7: begin
                if (col >= 5 && col <= 8) begin
                    case (col - 5)
                        0: char_code = "r"; 1: char_code = "s"; 2: char_code = "1"; 3: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 10 && col <= 11) begin
                    char_code = hex5_char(rs1, 1'(col - 10));
                end
                
                if (col >= 20 && col <= 28) begin
                    case (col - 20)
                        0: char_code = "r"; 1: char_code = "s"; 2: char_code = "1"; 3: char_code = "_"; 4: char_code = "d"; 5: char_code = "a"; 6: char_code = "t"; 7: char_code = "a"; 8: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 30 && col <= 37) begin
                    char_code = hex32_char(rs1_data, 4'(col - 30));
                end
            end
            
            6'd8: begin
                if (col >= 5 && col <= 8) begin
                    case (col - 5)
                        0: char_code = "r"; 1: char_code = "s"; 2: char_code = "2"; 3: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 10 && col <= 11) begin
                    char_code = hex5_char(rs2, 1'(col - 10));
                end
                
                if (col >= 20 && col <= 28) begin
                    case (col - 20)
                        0: char_code = "r"; 1: char_code = "s"; 2: char_code = "2"; 3: char_code = "_"; 4: char_code = "d"; 5: char_code = "a"; 6: char_code = "t"; 7: char_code = "a"; 8: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 30 && col <= 37) begin
                    char_code = hex32_char(rs2_data, 4'(col - 30));
                end
            end
            
            6'd9: begin
                if (col >= 5 && col <= 7) begin
                    case (col - 5)
                        0: char_code = "r"; 1: char_code = "d"; 2: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 9 && col <= 10) begin
                    char_code = hex5_char(rd, 1'(col - 9));
                end
                
                if (col >= 20 && col <= 32) begin
                    case (col - 20)
                        0: char_code = "R"; 1: char_code = "e"; 2: char_code = "g"; 3: char_code = " "; 4: char_code = "W"; 5: char_code = "r"; 6: char_code = "i"; 7: char_code = "t"; 8: char_code = "e"; 9: char_code = "E"; 10: char_code = "N"; 11: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col == 34) begin
                    char_code = bit_char(reg_write);
                end
            end

            6'd11: begin
                if (col >= 5 && col <= 11) begin
                    case (col - 5)
                        0: char_code = "A"; 1: char_code = "L"; 2: char_code = "U"; 3: char_code = "_"; 4: char_code = "A"; 5: char_code = ":"; 6: char_code = " ";
                        default: char_code = " ";
                    endcase
                end else if (col >= 13 && col <= 20) begin
                    char_code = hex32_char(ALU_A, 4'(col - 13));
                end
                
                if (col >= 25 && col <= 31) begin
                    case (col - 25)
                        0: char_code = "A"; 1: char_code = "L"; 2: char_code = "U"; 3: char_code = "_"; 4: char_code = "B"; 5: char_code = ":"; 6: char_code = " ";
                        default: char_code = " ";
                    endcase
                end else if (col >= 33 && col <= 40) begin
                    char_code = hex32_char(ALU_B, 4'(col - 33));
                end
            end
            
            6'd12: begin
                if (col >= 5 && col <= 13) begin
                    case (col - 5)
                        0: char_code = "A"; 1: char_code = "L"; 2: char_code = "U"; 3: char_code = "_"; 4: char_code = "r"; 5: char_code = "e"; 6: char_code = "s"; 7: char_code = ":"; 8: char_code = " ";
                        default: char_code = " ";
                    endcase
                end else if (col >= 15 && col <= 22) begin
                    char_code = hex32_char(ALU_res, 4'(col - 15));
                end
            end
            
            6'd14: begin
                if (col >= 5 && col <= 14) begin
                    case (col - 5)
                        0: char_code = "M"; 1: char_code = "e"; 2: char_code = "m"; 3: char_code = " "; 4: char_code = "W"; 5: char_code = "r"; 6: char_code = "i"; 7: char_code = "t"; 8: char_code = "e"; 9: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col == 16) begin
                    char_code = bit_char(mem_write);
                end
                
                if (col >= 20 && col <= 29) begin
                    case (col - 20)
                        0: char_code = "M"; 1: char_code = "e"; 2: char_code = "m"; 3: char_code = " "; 4: char_code = "t"; 5: char_code = "o"; 6: char_code = " "; 7: char_code = "R"; 8: char_code = "e"; 9: char_code = "g"; 10: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col == 31) begin
                    char_code = bit_char(mem_to_reg);
                end
            end
            
            6'd15: begin
                if (col >= 5 && col <= 13) begin
                    case (col - 5)
                        0: char_code = "M"; 1: char_code = "e"; 2: char_code = "m"; 3: char_code = "_"; 4: char_code = "D"; 5: char_code = "a"; 6: char_code = "t"; 7: char_code = "a"; 8: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 15 && col <= 22) begin
                    char_code = hex32_char(mem_data, 4'(col - 15));
                end
                
                if (col >= 25 && col <= 32) begin
                    case (col - 25)
                        0: char_code = "D"; 1: char_code = "a"; 2: char_code = "t"; 3: char_code = "a"; 4: char_code = "_"; 5: char_code = "W"; 6: char_code = "r"; 7: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col >= 34 && col <= 41) begin
                    char_code = hex32_char(data_wr, 4'(col - 34));
                end
            end
            
            6'd17: begin
                if (col >= 5 && col <= 17) begin
                    case (col - 5)
                        0: char_code = "B"; 1: char_code = "r"; 2: char_code = "a"; 3: char_code = "n"; 4: char_code = "c"; 5: char_code = "h"; 6: char_code = " "; 7: char_code = "T"; 8: char_code = "a"; 9: char_code = "k"; 10: char_code = "e"; 11: char_code = "n"; 12: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col == 19) begin
                    char_code = bit_char(branch_taken);
                end
                
                if (col >= 25 && col <= 29) begin
                    case (col - 25)
                        0: char_code = "J"; 1: char_code = "u"; 2: char_code = "m"; 3: char_code = "p"; 4: char_code = ":";
                        default: char_code = " ";
                    endcase
                end else if (col == 31) begin
                    char_code = bit_char(jump);
                end
            end
            
            default: char_code = 8'h20;
        endcase
    end

    // Output colors
    always_comb begin
        if (video_on) begin
            if (font_bit) begin
                VGA_R = 8'h00;
                VGA_G = 8'hFF;
                VGA_B = 8'h00;
            end else begin
                VGA_R = 8'h00;
                VGA_G = 8'h00;
                VGA_B = 8'h00;
            end
        end else begin
            VGA_R = 8'h00;
            VGA_G = 8'h00;
            VGA_B = 8'h00;
        end
    end
endmodule
