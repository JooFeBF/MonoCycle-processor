

package rv_config_pkg;

    localparam int DMEM_WORDS = 128;
    localparam int DMEM_ADDR_WIDTH = $clog2(DMEM_WORDS); 

    localparam int IMEM_WORDS = 128;
    localparam int IMEM_ADDR_WIDTH = $clog2(IMEM_WORDS); 

    localparam IMEM_INIT_FILE = "program.hex";
    localparam DMEM_INIT_FILE = "program_data.hex";

endpackage