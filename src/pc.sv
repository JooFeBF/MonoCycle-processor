

module pc (
    input  logic        clk,
    input  logic        rst,
    input  logic        pc_write,
    input  logic [31:0] next_pc,
    output logic [31:0] pc_out
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= 32'b0;
        else if (pc_write)
            pc_out <= next_pc;
    end

endmodule
