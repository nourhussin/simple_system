/////////////////////////////////////////////////////////////
/////////////////////// Clock Gating ////////////////////////
/////////////////////////////////////////////////////////////

module CLK_GATE (
    input  logic CLK_EN,
    input  logic CLK,
    output logic GATED_CLK
);

    // Internal latch output
    logic Latch_Out;

    // Level-sensitive latch (transparent when CLK = 0)
    always_latch begin
        if (!CLK) begin
            Latch_Out <= CLK_EN;
        end
    end

    // Clock AND gating
    assign GATED_CLK = CLK & Latch_Out;

endmodule
