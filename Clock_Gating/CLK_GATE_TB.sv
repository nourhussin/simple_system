`timescale 1ns/1ps

module CLK_GATE_TB;

    // DUT signals
    logic CLK;
    logic CLK_EN;
    logic GATED_CLK;

    // Instantiate DUT
    CLK_GATE dut (
        .CLK     (CLK),
        .CLK_EN  (CLK_EN),
        .GATED_CLK (GATED_CLK)
    );

    
    // Clock generator: 100 MHz (10 ns period)
    initial CLK = 0;
    always #5 CLK = ~CLK;

   
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, CLK_GATE_TB);
    end

  
    initial begin
        CLK_EN = 0;

        $display("Time   CLK  EN  GATED");
        $monitor("%4t    %b    %b    %b", $time, CLK, CLK_EN, GATED_CLK);

        // Wait for a few cycles
        repeat (3) @(negedge CLK);

        // Enable clock while CLK is LOW (correct case)
        CLK_EN = 1;
        @(negedge CLK);

        // Run gated clock
        repeat (6) @(posedge CLK);

        // Disable clock while CLK is HIGH (should not glitch)
        CLK_EN = 0;
        repeat (6) @(posedge CLK);

        // Re-enable while CLK low again
        @(negedge CLK);
        CLK_EN = 1;
        repeat (6) @(posedge CLK);
        $finish;
    end

endmodule
