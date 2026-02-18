module rptr_handler
#(
    parameter int depth = 8
)
(
    input  logic                     rclk,
    input  logic                     rrst_n,
    input  logic [$clog2(depth):0]   g_wptr_sync,
    input  logic                     r_en,

    output logic [$clog2(depth):0]   b_rptr,
    output logic [$clog2(depth):0]   g_rptr,
    output logic                     empty
);

    // Internal signals
    logic [$clog2(depth):0] b_rptr_con;
    logic incr;

    // Connect internal binary pointer
    assign b_rptr_con = b_rptr;

    // Increment logic
    assign incr = r_en & ~empty;

    // Empty flag
    assign empty = (g_rptr == g_wptr_sync);

    // Binary → Gray conversion
    bin2gray #(.WIDTH($clog2(depth)+1)) B2G (
        .bin (b_rptr_con),
        .gray(g_rptr)
    );

    //--------------------------------------------------
    // Read pointer update
    //--------------------------------------------------
    always_ff @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            b_rptr <= '0;
        else
            b_rptr <= b_rptr + incr;
    end

endmodule
