`timescale 1ns/1ps

module RegFile_TB;

    // Parameters
    localparam DATA_WIDTH    = 8;
    localparam ADDRESS_WIDTH = 4;

    // DUT signals
    logic CLK, RST;
    logic RdEn, WrEn;
    logic [DATA_WIDTH-1:0] WrData;
    logic [ADDRESS_WIDTH-1:0] Address;

    logic [DATA_WIDTH-1:0] RdData;
    logic RdData_Valid;
    logic [DATA_WIDTH-1:0] REG0, REG1, REG2, REG3;

    // Instantiate DUT
    RegFile #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDRESS_WIDTH(ADDRESS_WIDTH)
    ) dut (
        .CLK(CLK),
        .RST(RST),
        .RdEn(RdEn),
        .WrEn(WrEn),
        .WrData(WrData),
        .Address(Address),
        .RdData(RdData),
        .RdData_Valid(RdData_Valid),
        .REG0(REG0),
        .REG1(REG1),
        .REG2(REG2),
        .REG3(REG3)
    );

    always #5 CLK = ~CLK;

    task reset_dut;
        begin
            RST     = 0;
            RdEn    = 0;
            WrEn    = 0;
            WrData  = '0;
            Address = '0;
            #20;
            RST = 1;
        end
    endtask

    task write_reg(input logic [ADDRESS_WIDTH-1:0] addr,
                   input logic [DATA_WIDTH-1:0] data);
        begin
            @(posedge CLK);
            WrEn    = 1;
            RdEn    = 0;
            Address = addr;
            WrData  = data;
            @(posedge CLK);
            WrEn = 0;
        end
    endtask

    task read_reg(input logic [ADDRESS_WIDTH-1:0] addr,
                  input logic [DATA_WIDTH-1:0] expected);
        begin
            @(posedge CLK);
            RdEn    = 1;
            WrEn    = 0;
            Address = addr;
            @(posedge CLK);
            RdEn = 0;
        end
    endtask


    initial begin
        CLK = 0;

        reset_dut();
        #5;


        write_reg(0, 8'hA5);
        write_reg(1, 8'h3C);
        write_reg(2, 8'hFF);
        write_reg(3, 8'h11);


        read_reg(0, 8'hA5);
        read_reg(1, 8'h3C);
        read_reg(2, 8'hFF);
        read_reg(3, 8'h00);

        write_reg(1, 8'h55);
        read_reg(1, 8'h55);


        for (int i = 0; i < DATA_WIDTH; i++) begin
            write_reg(i[ADDRESS_WIDTH-1:0], (1 << i));
        end

        for (int i = 0; i < DATA_WIDTH; i++) begin
            read_reg(i[ADDRESS_WIDTH-1:0], (1 << i));
        end

        #20;
        $finish;
    end

endmodule
