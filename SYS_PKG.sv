package SYS_PKG;
    typedef logic [7:0] dataframe_t;
    typedef enum logic [3:0] {
    OP_ADD   = 4'd0,
    OP_SUB   = 4'd1,
    OP_MULT  = 4'd2,
    OP_DIV   = 4'd3,
    OP_AND   = 4'd4,
    OP_OR    = 4'd5,
    OP_NAND  = 4'd6,
    OP_NOR   = 4'd7,
    OP_XOR   = 4'd8,
    OP_XNOR  = 4'd9,
    OP_CMPE  = 4'd10,  // equal
    OP_CMPG  = 4'd11,  // greater
    OP_SR    = 4'd12,  // shift right
    OP_SL    = 4'd13   // shift left
} opcode_t;

endpackage