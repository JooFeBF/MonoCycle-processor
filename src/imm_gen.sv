import rv_opcodes_pkg::*;

module imm_gen(
    input  logic [31:0] instruction,
    input  logic [2:0]  immsrc_type,
    output logic [31:0] immediate_out
);

    always_comb begin
        case (immsrc_type)
            IMM_I_TYPE: immediate_out = {{20{instruction[31]}}, instruction[31:20]};
            
            // Sign-extension for Store instructions splits the immediate fields
            IMM_S_TYPE: immediate_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            
            // Branch instructions omit the 0th bit
            IMM_B_TYPE: immediate_out = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            
            IMM_U_TYPE: immediate_out = {instruction[31:12], 12'b0};
            
            IMM_J_TYPE: immediate_out = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            
            default:    immediate_out = 32'b0;
        endcase
    end

endmodule
