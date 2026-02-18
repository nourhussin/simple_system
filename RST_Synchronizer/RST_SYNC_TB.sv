`timescale 1ns/1ps

module RST_SYNC_TB;

    logic CLK;
    logic RST;
    logic SYNC_RST;

    // DUT (2-stage synchronizer)
    RST_SYNC #(.NUM_STAGES(2)) dut (
        .CLK(CLK),
        .RST(RST),
        .SYNC_RST(SYNC_RST)
    );

    //--------------------------------------------------
    // 100 MHz clock
    //--------------------------------------------------
    initial CLK = 0;
    always #5 CLK = ~CLK;

    //--------------------------------------------------
    // VCD
    //--------------------------------------------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, RST_SYNC_TB);
    end

    //--------------------------------------------------
    // Test
    //--------------------------------------------------
    initial begin
        // Apply async reset
        RST = 0;
        #12;

        // Release reset asynchronously (not aligned to clock)
        #7;
        RST = 1;

        // SYNC_RST must stay LOW for 2 clock cycles
        repeat (2) @(posedge CLK);

        // After 2 stages → SYNC_RST must go HIGH
        @(posedge CLK);

        //------------------------------------
        // Re-assert async reset
        //------------------------------------
        #3;
        RST = 0;
        #20;

        $finish;
    end

endmodule
