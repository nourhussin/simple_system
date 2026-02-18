module async_fifo
#(
    parameter int width = 32,
    parameter int depth = 8
)
(
    input  logic                   wclk,
    input  logic                   rclk,
    input  logic                   wrst_n,
    input  logic                   rrst_n,
    input  logic                   w_en,
    input  logic                   r_en,

    input  logic [width-1:0]       data_in,
    output logic [width-1:0]       data_out,
    output logic                   full,
    output logic                   empty
);

    //--------------------------------------------------
    // Local parameters
    //--------------------------------------------------
    localparam int ADD = $clog2(depth);

    //--------------------------------------------------
    // Internal signals
    //--------------------------------------------------
    logic [ADD:0] b_wptr, b_rptr;
    logic [ADD:0] g_wptr, g_rptr;
    logic [ADD:0] g_wptr_sync, g_rptr_sync;

    //--------------------------------------------------
    // Pointer synchronizers across clock domains
    //--------------------------------------------------
    sync_2ff #(.WIDTH(ADD+1)) RS (
        .clk   (rclk),
        .rst_n (rrst_n),
        .d_in  (g_wptr),
        .d_out (g_wptr_sync)
    );

    sync_2ff #(.WIDTH(ADD+1)) WS (
        .clk   (wclk),
        .rst_n (wrst_n),
        .d_in  (g_rptr),
        .d_out (g_rptr_sync)
    );

    //--------------------------------------------------
    // Read and write pointer handlers
    //--------------------------------------------------
    rptr_handler #(.depth(depth)) RH (
        .rclk        (rclk),
        .rrst_n      (rrst_n),
        .g_wptr_sync (g_wptr_sync),
        .r_en        (r_en),
        .b_rptr      (b_rptr),
        .g_rptr      (g_rptr),
        .empty       (empty)
    );

    wptr_handler #(.depth(depth)) WH (
        .wclk        (wclk),
        .wrst_n      (wrst_n),
        .g_rptr_sync (g_rptr_sync),
        .w_en        (w_en),
        .b_wptr      (b_wptr),
        .g_wptr      (g_wptr),
        .full        (full)
    );

    //--------------------------------------------------
    // Dual-clock memory
    //--------------------------------------------------
    fifo_mem #(
        .width(width),
        .depth(depth)
    ) MEM (
        .wclk   (wclk),
        .rclk   (rclk),
        .w_en   (w_en),
        .r_en   (r_en),
        .full   (full),
        .empty  (empty),

        .data_in (data_in),
        .b_wptr  (b_wptr),
        .b_rptr  (b_rptr),

        .data_out(data_out)
    );

endmodule
