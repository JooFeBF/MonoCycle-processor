import rv_config_pkg::*;

module data_memory (
    input  logic        clk,
    input  logic [31:0] address,
    input  logic [31:0] DMWR,
    input  logic [2:0]  DMCTRL,
    input  logic        mem_write,
    output logic  [31:0] Datard
);

    /* verilator lint_off UNOPTFLAT */
    logic [31:0] memory [0:DMEM_WORDS-1];
    /* verilator lint_on UNOPTFLAT */

    logic [DMEM_ADDR_WIDTH-1:0] word_addr;
    assign word_addr = address[DMEM_ADDR_WIDTH+1:2];
    logic [1:0] byte_offset;
    assign byte_offset = address[1:0];

    initial begin

        memory = '{default: 32'h00000000};
        $readmemh(DMEM_INIT_FILE, memory);
    end

    always_comb begin
        case (DMCTRL)
            3'b000: begin
                case (byte_offset)
                    2'b00: Datard = {{24{memory[word_addr][7]}}, memory[word_addr][7:0]};
                    2'b01: Datard = {{24{memory[word_addr][15]}}, memory[word_addr][15:8]};
                    2'b10: Datard = {{24{memory[word_addr][23]}}, memory[word_addr][23:16]};
                    2'b11: Datard = {{24{memory[word_addr][31]}}, memory[word_addr][31:24]};
                endcase
            end

            3'b001: begin
                case (byte_offset[1])
                    1'b0: Datard = {{16{memory[word_addr][15]}}, memory[word_addr][15:0]};
                    1'b1: Datard = {{16{memory[word_addr][31]}}, memory[word_addr][31:16]};
                endcase
            end

            3'b010: begin
                Datard = memory[word_addr];
            end

            3'b100: begin
                case (byte_offset)
                    2'b00: Datard = {24'b0, memory[word_addr][7:0]};
                    2'b01: Datard = {24'b0, memory[word_addr][15:8]};
                    2'b10: Datard = {24'b0, memory[word_addr][23:16]};
                    2'b11: Datard = {24'b0, memory[word_addr][31:24]};
                endcase
            end

            3'b101: begin
                case (byte_offset[1])
                    1'b0: Datard = {16'b0, memory[word_addr][15:0]};
                    1'b1: Datard = {16'b0, memory[word_addr][31:16]};
                endcase
            end

            default: begin
                Datard = 32'h00000000;
            end
        endcase
    end

    logic                     wr_pending;
    logic [DMEM_ADDR_WIDTH-1:0] wr_addr;
    logic [1:0]               wr_byte_offset;
    logic [2:0]               wr_ctrl;
    logic [31:0]              wr_data;

    always_latch begin
        if (clk) begin
            wr_pending = mem_write;
            wr_addr = word_addr;
            wr_byte_offset = byte_offset;
            wr_ctrl = DMCTRL;
            wr_data = DMWR;
        end
    end

    always_latch begin
        if (~clk) begin
            if (wr_pending) begin
                case (wr_ctrl)
                    3'b000, 3'b100: begin
                        case (wr_byte_offset)
                            2'b00: memory[wr_addr] = {memory[wr_addr][31:8], wr_data[7:0]};
                            2'b01: memory[wr_addr] = {memory[wr_addr][31:16], wr_data[7:0], memory[wr_addr][7:0]};
                            2'b10: memory[wr_addr] = {memory[wr_addr][31:24], wr_data[7:0], memory[wr_addr][15:0]};
                            2'b11: memory[wr_addr] = {wr_data[7:0], memory[wr_addr][23:0]};
                        endcase
                    end

                    3'b001, 3'b101: begin
                        case (wr_byte_offset[1])
                            1'b0: memory[wr_addr] = {memory[wr_addr][31:16], wr_data[15:0]};
                            1'b1: memory[wr_addr] = {wr_data[15:0], memory[wr_addr][15:0]};
                        endcase
                    end

                    3'b010: begin
                        memory[wr_addr] = wr_data;
                    end
                    
                    default: begin
                    end
                endcase
            end
        end
    end

endmodule
