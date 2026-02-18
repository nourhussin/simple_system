module wptr_handler
#(
    parameter int depth = 8
)
(
    input  logic                     wclk,
    input  logic                     wrst_n,
    input  logic [$clog2(depth):0]    g_rptr_sync,
    input  logic                     w_en,

    output logic [$clog2(depth):0]    b_wptr,
    output logic [$clog2(depth):0]    g_wptr,
    output logic                     full
);

    localparam int ADD = $clog2(depth);

    logic [ADD:0] b_rptr;
    logic [ADD:0] b_wptr_con;
    logic         incr;

    // Continuous assignments
    assign b_wptr_con = b_wptr;
    assign incr      = w_en & ~full;

    // Full condition (binary comparison)
    assign full =
        (b_wptr_con[ADD-1:0] == b_rptr[ADD-1:0]) &&
        (b_wptr_con[ADD]     != b_rptr[ADD]);

    // Binary ↔ Gray conversions
    bin2gray #(ADD + 1) B2G (
        .bin (b_wptr_con),
        .gray(g_wptr)
    );

    gray2bin #(ADD + 1) G2B (
        .gray(g_rptr_sync),
        .bin (b_rptr)
    );

    //--------------------------------------------------
    // Write pointer
    //--------------------------------------------------
    always_ff @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            b_wptr <= '0;
        else
            b_wptr <= b_wptr + incr;
    end

endmodule
