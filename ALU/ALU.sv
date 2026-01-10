import SYS_PKG::*;

module ALU #(parameter DATA_WIDTH)(
    input logic CLK, RST,
    input logic Enable,

    input logic [DATA_WIDTH-1 : 0] A,B,
    input opcode_t ALU_FUN,

    output logic [2*DATA_WIDTH-1 : 0] ALU_OUT,
    output logic OUT_VALID
);

    always_ff @(posedge CLK or posedge RST) begin
        if (!RST) begin
            ALU_OUT  <= '0;
            OUT_VALID <= 1'b0;
        end
        else if (Enable) begin
            OUT_VALID <= 1'b1;

            case (ALU_FUN)

                OP_ADD  : ALU_OUT <= A + B;
                OP_SUB  : ALU_OUT <= A - B;
                OP_MULT : ALU_OUT <= A * B;
                OP_DIV  : begin
                    if(B==0) begin
                        OUT_VALID <= 0;
                        ALU_OUT <= 0;
                    end else begin
                        ALU_OUT <= A / B;
                    end
                end

                OP_AND  : ALU_OUT <= A & B;
                OP_OR   : ALU_OUT <= A | B;
                OP_NAND : ALU_OUT <= ~(A & B);
                OP_NOR  : ALU_OUT <= ~(A | B);
                OP_XOR  : ALU_OUT <= A ^ B;
                OP_XNOR : ALU_OUT <= ~(A ^ B);

                OP_CMPE : ALU_OUT <= (A == B);
                OP_CMPG : ALU_OUT <= (A >  B);

                OP_SR   : ALU_OUT <= A >> 1;
                OP_SL   : ALU_OUT <= A << 1;

                default : begin
                    ALU_OUT <= '0;
                    OUT_VALID <= 0;
                end
            endcase
        end
        else begin
            OUT_VALID <= 1'b0;
        end
    end

endmodule