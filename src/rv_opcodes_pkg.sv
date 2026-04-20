package rv_opcodes_pkg;

    localparam logic [6:0] OPC_R_TYPE = 7'b0110011;
    localparam logic [6:0] OPC_I_TYPE = 7'b0010011;
    localparam logic [6:0] OPC_LOAD   = 7'b0000011;
    localparam logic [6:0] OPC_STORE  = 7'b0100011;
    localparam logic [6:0] OPC_BRANCH = 7'b1100011;
    localparam logic [6:0] OPC_JAL    = 7'b1101111;
    localparam logic [6:0] OPC_JALR   = 7'b1100111;
    localparam logic [6:0] OPC_LUI    = 7'b0110111;
    localparam logic [6:0] OPC_AUIPC  = 7'b0010111;

    localparam logic [3:0] ALU_AND  = 4'b0000;
    localparam logic [3:0] ALU_OR   = 4'b0001;
    localparam logic [3:0] ALU_ADD  = 4'b0010;
    localparam logic [3:0] ALU_XOR  = 4'b0011;
    localparam logic [3:0] ALU_SLL  = 4'b0100;
    localparam logic [3:0] ALU_SRL  = 4'b0101;
    localparam logic [3:0] ALU_SUB  = 4'b0110;
    localparam logic [3:0] ALU_SRA  = 4'b0111;
    localparam logic [3:0] ALU_SLT  = 4'b1000;
    localparam logic [3:0] ALU_SLTU = 4'b1001;

    localparam logic [2:0] IMM_I_TYPE = 3'b000;
    localparam logic [2:0] IMM_S_TYPE = 3'b001;
    localparam logic [2:0] IMM_B_TYPE = 3'b010;
    localparam logic [2:0] IMM_U_TYPE = 3'b011;
    localparam logic [2:0] IMM_J_TYPE = 3'b100;


    localparam logic [2:0] BR_BEQ  = 3'b000;
    localparam logic [2:0] BR_BNE  = 3'b001;
    localparam logic [2:0] BR_BLT  = 3'b100;
    localparam logic [2:0] BR_BGE  = 3'b101;
    localparam logic [2:0] BR_BLTU = 3'b110;
    localparam logic [2:0] BR_BGEU = 3'b111;

endpackage

