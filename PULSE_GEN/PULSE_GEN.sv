module PULSE_GEN
(
    input  logic CLK,
    input  logic RST,          // active-low
    input  logic LVL_SIG,
    output logic PULSE_SIG
);

    logic current_flop;
    logic prev_flop;

    //--------------------------------------------------
    // Two-flop synchronizer + edge detector
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST) begin
            current_flop <= 1'b0;
            prev_flop    <= 1'b0;
        end
        else begin
            current_flop <= LVL_SIG;
            prev_flop    <= current_flop;
        end
    end

    // Rising-edge pulse (1-cycle wide)
    assign PULSE_SIG = current_flop & ~prev_flop;

endmodule
