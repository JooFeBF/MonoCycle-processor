import rv_opcodes_pkg::*;

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    
    output logic [3:0] alu_op,
    output logic       alu_src,
    output logic       reg_write,
    output logic       mem_to_reg,
    output logic       mem_write,
    output logic       branch,
    output logic       jump,
    output logic [2:0] branch_type,
    output logic [2:0] immsrc_type
);

    always_comb begin
        
        alu_op      = ALU_AND;
        alu_src     = 1'b0;
        reg_write   = 1'b0;
        mem_to_reg  = 1'b0;
        mem_write   = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        branch_type = 3'b000;
        immsrc_type = IMM_I_TYPE;

        case (opcode)

            OPC_R_TYPE: begin
                alu_src     = 1'b0;
                reg_write   = 1'b1;
                immsrc_type = IMM_I_TYPE; 

                case ({funct7, funct3})
                    10'b0000000_000: alu_op = ALU_ADD;
                    10'b0100000_000: alu_op = ALU_SUB; 
                    10'b0000000_111: alu_op = ALU_AND; 
                    10'b0000000_110: alu_op = ALU_OR; 
                    10'b0000000_100: alu_op = ALU_XOR; 
                    10'b0000000_010: alu_op = ALU_SLT; 
                    10'b0000000_011: alu_op = ALU_SLTU; 
                    10'b0000000_001: alu_op = ALU_SLL; 
                    10'b0000000_101: alu_op = ALU_SRL; 
                    10'b0100000_101: alu_op = ALU_SRA; 
                    default:         alu_op = ALU_AND;
                endcase
            end

            OPC_I_TYPE: begin
                alu_src     = 1'b1;
                reg_write   = 1'b1;
                immsrc_type = IMM_I_TYPE; 

                case (funct3)
                    3'b000: alu_op = ALU_ADD; 
                    3'b100: alu_op = ALU_XOR; 
                    3'b110: alu_op = ALU_OR; 
                    3'b111: alu_op = ALU_AND; 
                    3'b010: alu_op = ALU_SLT; 
                    3'b011: alu_op = ALU_SLTU; 
                    3'b001: alu_op = ALU_SLL; 
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            alu_op = ALU_SRL; 
                        else if (funct7 == 7'b0100000)
                            alu_op = ALU_SRA; 
                    end
                    default: alu_op = ALU_AND;
                endcase
            end

            OPC_LOAD: begin
                alu_src     = 1'b1;
                alu_op      = ALU_ADD; 
                reg_write   = 1'b1;
                mem_to_reg  = 1'b1;
                immsrc_type = IMM_I_TYPE;  
            end

            OPC_STORE: begin
                alu_src     = 1'b1;
                alu_op      = ALU_ADD; 
                mem_write   = 1'b1;
                immsrc_type = IMM_S_TYPE;  
            end

            OPC_BRANCH: begin
                alu_src     = 1'b0;
                alu_op      = ALU_SUB; 
                branch      = 1'b1;
                branch_type = funct3;
                immsrc_type = IMM_B_TYPE; 
            end

            OPC_LUI: begin
                alu_src     = 1'b1;
                alu_op      = ALU_OR; 
                reg_write   = 1'b1;
                immsrc_type = IMM_U_TYPE;  
            end

            OPC_AUIPC: begin
                alu_src     = 1'b1;
                alu_op      = ALU_ADD; 
                reg_write   = 1'b1;
                immsrc_type = IMM_U_TYPE;  
            end

            OPC_JAL: begin
                alu_src     = 1'b1;
                alu_op      = ALU_ADD; 
                reg_write   = 1'b1;
                jump        = 1'b1;
                immsrc_type = IMM_J_TYPE;  
            end

            OPC_JALR: begin
                alu_src     = 1'b1;
                alu_op      = ALU_ADD; 
                reg_write   = 1'b1;
                jump        = 1'b1;
                immsrc_type = IMM_I_TYPE;  
            end

            default: begin
            end
        endcase
    end

endmodule
