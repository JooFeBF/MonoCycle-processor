

module registers_unit (
    input  logic        clk,
    input  logic        rst,      

    input  logic [4:0]  rs1,
    input  logic [4:0]  rs2,
    input  logic [4:0]  rd,

    input  logic        ru_wr,     
    input  logic [31:0] data_wr,   

    output logic [31:0] rs1_data,
    output logic [31:0] rs2_data
);

    /* verilator lint_off UNOPTFLAT */
    logic [31:0] registers [0:31];
    /* verilator lint_on UNOPTFLAT */

    // Synchronous register write for RAM block inference
    always @(negedge clk) begin
        if (ru_wr && (rd != 5'd0)) begin
            registers[rd] <= data_wr;
        end
    end

    assign rs1_data = (rs1 == 5'd0) ? 32'b0 : registers[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'b0 : registers[rs2];

endmodule
