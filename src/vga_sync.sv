module vga_sync (
    input  logic clk_25mhz,
    input  logic rst_n,
    output logic hsync,
    output logic vsync,
    output logic video_on,
    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y
);

    // VGA Timing parameters for 640x480 @ 60Hz
    localparam H_DISPLAY = 640;
    localparam H_FP      = 16;
    localparam H_SYNC    = 96;
    localparam H_BP      = 48;
    localparam H_TOTAL   = 800;

    localparam V_DISPLAY = 480;
    localparam V_FP      = 10;
    localparam V_SYNC    = 2;
    localparam V_BP      = 33;
    localparam V_TOTAL   = 525;

    logic [9:0] h_count_reg, h_count_next;
    logic [9:0] v_count_reg, v_count_next;

    // Registers for horizontal and vertical counters
    always_ff @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            h_count_reg <= 10'd0;
            v_count_reg <= 10'd0;
        end else begin
            h_count_reg <= h_count_next;
            v_count_reg <= v_count_next;
        end
    end

    // Next-state logic for counters
    always_comb begin
        h_count_next = h_count_reg;
        v_count_next = v_count_reg;

        if (h_count_reg == H_TOTAL - 1) begin
            h_count_next = 10'd0;
            if (v_count_reg == V_TOTAL - 1) begin
                v_count_next = 10'd0;
            end else begin
                v_count_next = v_count_reg + 1'b1;
            end
        end else begin
            h_count_next = h_count_reg + 1'b1;
        end
    end

    // Output assignments
    // Sync signals are active low
    assign hsync = ~(h_count_reg >= (H_DISPLAY + H_FP) && h_count_reg < (H_DISPLAY + H_FP + H_SYNC));
    assign vsync = ~(v_count_reg >= (V_DISPLAY + V_FP) && v_count_reg < (V_DISPLAY + V_FP + V_SYNC));
    
    // Video on during active display area
    assign video_on = (h_count_reg < H_DISPLAY) && (v_count_reg < V_DISPLAY);
    
    // Pixel coordinates
    assign pixel_x = h_count_reg;
    assign pixel_y = v_count_reg;

endmodule
