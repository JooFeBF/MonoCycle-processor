

module registers_unit (
    input  logic        clk,
    input  logic        rst,      

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,

    input  logic        ru_wr,     
    input  logic [31:0] data_wr,   

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data,
    output logic [31:0] registers [0:31]
);

    /* verilator lint_off UNOPTFLAT */
    logic [31:0] reg_array [0:31];
    /* verilator lint_on UNOPTFLAT */
    
    assign registers = reg_array;

    // Synchronous register write for RAM block inference
    always @(negedge clk) begin
        if (rst) begin
            for (int i = 1; i < 32; i++) begin
                reg_array[i] <= 32'h0;
            end
            reg_array[0] <= 32'h0;
        end else if (ru_wr && (rd != 5'd0)) begin
            reg_array[rd] <= data_wr;
        end
    end

    assign rs1_data = (rs1 == 5'd0) ? 32'b0 : reg_array[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'b0 : reg_array[rs2];

endmodule
