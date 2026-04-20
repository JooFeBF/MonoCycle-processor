import rv_opcodes_pkg::*;

module branch_unit (
    input  logic [31:0] rs1_data,
    input  logic [31:0] rs2_data,
    input  logic [2:0]  branch_type,
    input  logic        branch,
    output logic        branch_taken
);

    logic signed [31:0] signed_rs1;
    logic signed [31:0] signed_rs2;
    
    assign signed_rs1 = rs1_data;
    assign signed_rs2 = rs2_data;

    always_comb begin
        if (branch) begin
            case (branch_type)
                BR_BEQ:  branch_taken = (rs1_data == rs2_data);
                BR_BNE:  branch_taken = (rs1_data != rs2_data);
                BR_BLT:  branch_taken = (signed_rs1 < signed_rs2);
                BR_BGE:  branch_taken = (signed_rs1 >= signed_rs2);
                BR_BLTU: branch_taken = (rs1_data < rs2_data);
                BR_BGEU: branch_taken = (rs1_data >= rs2_data);
                default: branch_taken = 1'b0;
            endcase
        end else begin
            branch_taken = 1'b0;
        end
    end

endmodule
