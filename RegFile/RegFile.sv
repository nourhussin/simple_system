module RegFile #(parameter DATA_WIDTH = 8, ADDRESS_WIDTH = 4)(
    
    input logic CLK, RST,
    input logic RdEn, WrEn,
    input logic [DATA_WIDTH-1 : 0] WrData,
    input logic [ADDRESS_WIDTH-1 : 0] Address,

    output logic [DATA_WIDTH-1 : 0] RdData,
    output logic RdData_Valid,
    output logic [DATA_WIDTH-1 : 0] REG0, REG1, REG2, REG3

);
    localparam int DEPTH = 1 << ADDRESS_WIDTH;
    logic [DATA_WIDTH-1 : 0] regfile[0 : DEPTH-1];

    assign REG0 = regfile[0];
    assign REG1 = regfile[1];
    assign REG2 = regfile[2];
    assign REG3 = regfile[3];

    always_ff@(posedge CLK or posedge RST) begin
        if(!RST) begin
            for (int i = 0; i < 16; i++)
                regfile[i] <= '0;

        end else if (WrEn) begin
            regfile[Address] <= WrData;

        end else if (RdEn) begin
            RdData <= regfile[Address];
            RdData_Valid <= 1'b1;

        end else begin
            RdData <= 0;
            RdData_Valid <= 1'b0;
        end
    end



endmodule