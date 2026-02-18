module gray2bin
#(
    parameter int WIDTH = 4
)
(
    input  logic [WIDTH-1:0] gray,
    output logic [WIDTH-1:0] bin
);

    //--------------------------------------------------
    // Gray → Binary function
    //--------------------------------------------------
    function logic [WIDTH-1:0] gray_to_bin(input logic [WIDTH-1:0] g);
        integer j;
        logic [WIDTH-1:0] b;
        begin
            b[WIDTH-1] = g[WIDTH-1];
            for (j = WIDTH-2; j >= 0; j = j - 1)
                b[j] = b[j+1] ^ g[j];
            gray_to_bin = b;
        end
    endfunction

    //--------------------------------------------------
    // Assign combinational output
    //--------------------------------------------------
    assign bin = gray_to_bin(gray);

endmodule
