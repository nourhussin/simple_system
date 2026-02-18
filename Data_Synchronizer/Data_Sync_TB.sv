`timescale 1ns/1ps

module Data_Sync_TB;

    localparam BUS_WIDTH = 8;

    logic dest_clk;
    logic dest_rst;
    logic bus_enable;
    logic [BUS_WIDTH-1:0] unsync_bus;
    logic [BUS_WIDTH-1:0] sync_bus;
    logic enable_pulse;

    Data_Sync #(.BUS_WIDTH(BUS_WIDTH), .NUM_STAGES(2)) dut (
        .dest_clk(dest_clk),
        .dest_rst(dest_rst),
        .bus_enable(bus_enable),
        .unsync_bus(unsync_bus),
        .sync_bus(sync_bus),
        .enable_pulse(enable_pulse)
    );

    //--------------------------------------------------
    // 100 MHz clock
    //--------------------------------------------------
    initial dest_clk = 0;
    always #5 dest_clk = ~dest_clk;

    //--------------------------------------------------
    // VCD
    //--------------------------------------------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, Data_Sync_TB);
    end

    //--------------------------------------------------
    // Test
    //--------------------------------------------------
    initial begin
        dest_rst = 0;
        bus_enable = 0;
        unsync_bus = 8'h00;
        #20;
        dest_rst = 1;

        //----------------------------------------
        // Apply data
        //----------------------------------------
        unsync_bus = 8'hA5;
        bus_enable = 1;

        // wait for synchronizer (2 cycles)
        repeat (4) @(posedge dest_clk);
        bus_enable = 0;

        //----------------------------------------
        // Change data again
        //----------------------------------------
        unsync_bus = 8'h3C;
        repeat (2) @(posedge dest_clk);

        bus_enable = 1;
        repeat (5) @(posedge dest_clk);

        $finish;
    end

endmodule
