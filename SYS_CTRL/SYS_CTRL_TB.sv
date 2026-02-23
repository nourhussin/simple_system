`timescale 1ns/1ps

module SYS_CTRL_TB;

    // =====================================================
    // Clock & Reset
    // =====================================================
    logic CLK;
    logic RST;

    initial CLK = 0;
    always #5 CLK = ~CLK;   // 100MHz clock

    // =====================================================
    // DUT Signals
    // =====================================================
    logic           OUT_Valid;
    logic           RdData_Valid;
    logic           RX_D_VLD;
    logic           FIFO_FULL;

    logic [15:0]    ALU_OUT;
    logic [7:0]     RdData;
    logic [7:0]     RX_P_Data;

    logic           WrEN;
    logic           RdEn;
    logic [3:0]     Address;
    logic [7:0]     WrData;

    logic [3:0]     ALU_FUN;
    logic           ALU_EN;
    logic           CLK_EN;

    logic           TX_D_VLD;
    logic [7:0]     TX_P_DATA;

    logic           clk_div_en;

    // =====================================================
    // Instantiate DUT
    // =====================================================
    SYS_CTRL dut (
        .CLK(CLK),
        .RST(RST),
        .OUT_Valid(OUT_Valid),
        .RdData_Valid(RdData_Valid),
        .RX_D_VLD(RX_D_VLD),
        .FIFO_FULL(FIFO_FULL),
        .ALU_OUT(ALU_OUT),
        .RdData(RdData),
        .RX_P_Data(RX_P_Data),
        .WrEN(WrEN),
        .RdEn(RdEn),
        .Address(Address),
        .WrData(WrData),
        .ALU_FUN(ALU_FUN),
        .ALU_EN(ALU_EN),
        .CLK_EN(CLK_EN),
        .TX_D_VLD(TX_D_VLD),
        .TX_P_DATA(TX_P_DATA),
        .clk_div_en(clk_div_en)
    );

    // =====================================================
    // Helper Task: Send UART Byte
    // =====================================================
    task send_byte(input [7:0] data);
    begin
        @(posedge CLK);
        RX_P_Data = data;
        RX_D_VLD  = 1'b1;
        @(posedge CLK);
        RX_D_VLD  = 1'b0;
    end
    endtask

    // =====================================================
    // Monitor TX activity
    // =====================================================
    always @(posedge CLK) begin
        if (TX_D_VLD)
            $display("Time %0t : TX Sent = 0x%0h", $time, TX_P_DATA);
    end

    // =====================================================
    // Test Sequence
    // =====================================================
    initial begin
        // ---- Init ----
        RX_D_VLD      = 0;
        OUT_Valid     = 0;
        RdData_Valid  = 0;
        FIFO_FULL     = 0;
        ALU_OUT       = 16'h0000;
        RdData        = 8'h00;

        RST = 0;
        #20;
        RST = 1;

        // =====================================================
        // TEST WRITE (0xAA)
        // Write 0x55 to address 0x3
        // =====================================================
        $display("---- TEST WRITE ----");
        send_byte(8'hAA);  // Write command
        send_byte(8'h03);  // Address
        send_byte(8'h55);  // Data
        // =====================================================
        // TEST READ (0xBB)
        // Read from address 0x3
        // =====================================================
        $display("---- TEST READ ----");
        send_byte(8'hBB);  // Read command
        send_byte(8'h03);  // Address

        // Simulate register file response
        #10;
        RdData       = 8'h55;
        RdData_Valid = 1'b1;
        #10;
        RdData_Valid = 1'b0;
        // =====================================================
        // TEST ALU NEW OPERANDS (0xCC)
        // A=5, B=3, FUNC=1
        // =====================================================
        $display("---- TEST ALU NEW ----");
        send_byte(8'hCC);  // Command
        send_byte(8'h05);  // Operand A
        send_byte(8'h03);  // Operand B
        send_byte(8'h01);  // Function

        // Simulate ALU result
        #10;
        ALU_OUT   = 16'h0008;
        OUT_Valid = 1'b1;
        #10;
        OUT_Valid = 1'b0;
        #40;
        // =====================================================
        // TEST ALU EXISTING OPERANDS (0xDD)
        // FUNC = 2
        // =====================================================
        $display("---- TEST ALU OLD ----");
        send_byte(8'hDD);
        send_byte(8'h02);

        // Simulate ALU result
        #10;
        ALU_OUT   = 16'h0002;
        OUT_Valid = 1'b1;
        #10;
        OUT_Valid = 1'b0;

        #80;

        $display("---- TEST COMPLETE ----");
        $finish;
    end

endmodule