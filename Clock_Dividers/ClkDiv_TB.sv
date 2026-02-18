`timescale 1ns/1ps

module ClkDiv_TB;

    logic i_ref_clk;
    logic i_rst_n;
    logic i_clk_en;
    logic [7:0] i_div_ratio;
    logic o_div_clk;

    // DUT
    ClkDiv dut (
        .i_ref_clk(i_ref_clk),
        .i_rst_n(i_rst_n),
        .i_div_ratio(i_div_ratio),
        .i_clk_en(i_clk_en),
        .o_div_clk(o_div_clk)
    );

    //--------------------------------------------------
    // 100 MHz reference clock
    //--------------------------------------------------
    initial i_ref_clk = 0;
    always #5 i_ref_clk = ~i_ref_clk;

    //--------------------------------------------------
    // Dump VCD
    //--------------------------------------------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, ClkDiv_TB);
    end

    //--------------------------------------------------
    // Test sequence
    //--------------------------------------------------
    initial begin
        $display("CLK_DIV TEST START");

        i_rst_n    = 0;
        i_clk_en    = 0;
        i_div_ratio = 0;

        #20;
        i_rst_n = 1;

        //-----------------------------------
        // Test bypass (divider disabled)
        //-----------------------------------
        i_clk_en    = 0;
        i_div_ratio = 8'd4;
        repeat (5) @(posedge i_ref_clk);

        //-----------------------------------
        // Test divide-by-4
        //-----------------------------------
        i_clk_en    = 1;
        i_div_ratio = 8'd4;

        repeat (20) @(posedge i_ref_clk);

        //-----------------------------------
        // Test divide-by-7 (odd divider)
        //-----------------------------------
        i_div_ratio = 8'd7;
        repeat (40) @(posedge i_ref_clk);

        //-----------------------------------
        // Disable divider again
        //-----------------------------------
        i_clk_en = 0;
        repeat (10) @(posedge i_ref_clk);

        $finish;
    end
endmodule
