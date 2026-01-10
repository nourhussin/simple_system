`timescale 1ns/1ps

import SYS_PKG::*;

module ALU_TB;

    localparam int DATA_WIDTH   = 8;
    localparam int OPCODE_WIDTH = 4;

    // DUT signals
    logic CLK, RST, Enable;
    logic [DATA_WIDTH-1:0] A, B;
    opcode_t ALU_FUN;
    logic [2*DATA_WIDTH-1:0] ALU_OUT;
    logic OUT_VALID;

    ALU #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .CLK(CLK),
        .RST(RST),
        .Enable(Enable),
        .A(A),
        .B(B),
        .ALU_FUN(ALU_FUN),
        .ALU_OUT(ALU_OUT),
        .OUT_VALID(OUT_VALID)
    );

    always #5 CLK = ~CLK;


    task automatic run_test(
        input logic [DATA_WIDTH-1:0] a,
        input logic [DATA_WIDTH-1:0] b,
        input logic [OPCODE_WIDTH-1:0] op
    );
        logic [2*DATA_WIDTH-1:0] exp;

        begin
            @(posedge CLK);
            Enable  = 1;
            A       = a;
            B       = b;
            ALU_FUN = opcode_t'(op);

            @(posedge CLK);
            Enable = 0;
        end
    endtask


    initial begin
        // Init
        CLK = 0;
        RST = 0;
        Enable = 0;
        A = 0;
        B = 0;
        ALU_FUN = opcode_t'(0);

        // Reset
        #20;
        RST = 1;


        for (int op = 0; op <= 13; op++) begin
            run_test(8'd15, 8'd3, op);
            run_test(8'd20, 8'd5, op);
            run_test(8'd7,  8'd7, op);
        end

        $finish;
    end

endmodule
