

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

    logic        wr_pending;
    logic [4:0]  wr_rd;
    logic [31:0] wr_data;

    // Phase 1: Capture write request on clock high (asynchronous latch)
    always @(clk or ru_wr or rd or data_wr) begin
        if (clk) begin
            wr_pending = ru_wr;
            wr_rd = rd;
            wr_data = data_wr;
        end
    end

    // Phase 2: Commit write on clock low (asynchronous write)
    always @(clk or wr_pending or wr_rd or wr_data) begin
        if (~clk && wr_pending && (wr_rd != 5'd0)) begin
            registers[wr_rd] = wr_data;
        end
    end

    assign rs1_data = (rs1 == 5'd0) ? 32'b0 : registers[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'b0 : registers[rs2];

endmodule
