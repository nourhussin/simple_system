`timescale 1ns/1ps

module PULSE_GEN_TB;

    logic CLK;
    logic RST;
    logic LVL_SIG;
    logic PULSE_SIG;

    // DUT
    PULSE_GEN dut (
        .CLK(CLK),
        .RST(RST),
        .LVL_SIG(LVL_SIG),
        .PULSE_SIG(PULSE_SIG)
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
        $dumpvars(0, PULSE_GEN_TB);
    end

    //--------------------------------------------------
    // Stimulus
    //--------------------------------------------------
    initial begin
        RST = 0;
        LVL_SIG  = 0;
        #20;
        RST = 1;

        //------------------------------------
        // No pulse when LVL_SIG stays low
        //------------------------------------
        repeat (5) @(posedge CLK);

        //------------------------------------
        // Rising edge → expect 1-cycle pulse
        //------------------------------------
        LVL_SIG = 1;
        repeat (2) @(posedge CLK);

        //------------------------------------
        // Keep LVL_SIG high → no more pulses
        //------------------------------------
        repeat (5) @(posedge CLK);

        //------------------------------------
        // Falling edge → no pulse
        //------------------------------------
        LVL_SIG = 0;
        repeat (3) @(posedge CLK);

        //------------------------------------
        // Rising again → new pulse
        //------------------------------------
        LVL_SIG = 1;
        repeat (2) @(posedge CLK);
        $finish;
    end

endmodule
