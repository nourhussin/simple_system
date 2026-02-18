module RST_SYNC
#(
    parameter int NUM_STAGES = 2
)
(
    input  logic CLK,
    input  logic RST,        // async active-low reset
    output logic SYNC_RST    // synchronized active-high reset
);

    // Shift register for synchronizer
    logic [NUM_STAGES-2:0] sync_reg;

    integer I;

    //--------------------------------------------------
    // Asynchronous assert, synchronous de-assert reset
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST) begin
            SYNC_RST <= 1'b0;
            sync_reg <= '0;
        end
        else begin
            // Shift in '1' to release reset synchronously
            {sync_reg, SYNC_RST} <= {1'b1, sync_reg};
        end
    end

endmodule
