module bin2gray
#(
    parameter int WIDTH = 4
)
(
    input  logic [WIDTH-1:0] bin,
    output logic [WIDTH-1:0] gray
);

    // Combinational binary → Gray conversion
    assign gray = bin ^ (bin >> 1);

endmodule
