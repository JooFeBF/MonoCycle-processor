

import rv_config_pkg::*;

module instruction_memory(
    input  logic        clk,
    input  logic [31:0] address,
    output logic [31:0] instruction
);

    logic [31:0] mem [0:IMEM_WORDS-1];

    initial begin
        mem = '{default: 32'h00000013};
        $readmemh(IMEM_INIT_FILE, mem);
    end

    assign instruction = mem[address[IMEM_ADDR_WIDTH+1:2]];

endmodule
