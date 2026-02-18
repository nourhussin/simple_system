module fifo_mem
#(
    parameter int width = 32,
    parameter int depth = 8
)
(
    input  logic                     wclk,
    input  logic                     rclk,
    input  logic                     w_en,
    input  logic                     r_en,
    input  logic                     full,
    input  logic                     empty,

    input  logic [width-1:0]         data_in,
    input  logic [$clog2(depth):0]   b_wptr,
    input  logic [$clog2(depth):0]   b_rptr,

    output logic [width-1:0]         data_out
);

    //--------------------------------------------------
    // Local parameters and addresses
    //--------------------------------------------------
    localparam int ADD = $clog2(depth);
    logic [ADD-1:0] w_addr , r_addr;
    assign w_addr = b_wptr[ADD-1:0];
    assign r_addr = b_rptr[ADD-1:0];

    //--------------------------------------------------
    // Memory array
    //--------------------------------------------------
    logic [width-1:0] mem [0:depth-1];

    //--------------------------------------------------
    // Write operation
    //--------------------------------------------------
    always_ff @(posedge wclk) begin
        if (w_en & ~full) begin
            mem[w_addr] <= data_in;
        end
    end

    //--------------------------------------------------
    // Read operation
    //--------------------------------------------------
    always_ff @(posedge rclk) begin
        if (r_en & ~empty) begin
            data_out <= mem[r_addr];
        end
    end

endmodule
