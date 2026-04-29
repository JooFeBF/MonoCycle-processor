module font_rom (
    input  logic        clk,
    input  logic [11:0] addr,
    output logic [7:0]  data
);

    logic [7:0] memory [0:4095];

    initial begin
        $readmemh("src/vga_font.hex", memory);
    end

    always_ff @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
