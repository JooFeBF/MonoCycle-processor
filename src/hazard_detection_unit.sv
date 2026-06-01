module hazard_detection_unit (
    input  logic [4:0] if_id_rs1,
    input  logic [4:0] if_id_rs2,
    input  logic [4:0] id_ex_rd,
    input  logic       id_ex_mem_to_reg,
    output logic       stall
);

    always_comb begin
        if (id_ex_mem_to_reg && (id_ex_rd != 5'b0) &&
            ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2)))
            stall = 1'b1;
        else
            stall = 1'b0;
    end

endmodule
