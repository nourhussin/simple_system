module SYS_CTRL
(
    input  logic           CLK,
    input  logic           RST,
    input  logic           OUT_Valid,
    input  logic           RdData_Valid,
    input  logic           RX_D_VLD,
    input  logic [15:0]    ALU_OUT,
    input  logic [7:0]     RdData,
    input  logic [7:0]     RX_P_Data,
    input  logic           FIFO_FULL,

    output logic [3:0]     ALU_FUN,
    output logic           WrEN,
    output logic           clk_div_en,
    output logic           TX_D_VLD,
    output logic           RdEn,
    output logic           CLK_EN,
    output logic           ALU_EN,
    output logic [3:0]     Address,
    output logic [7:0]     WrData,
    output logic [7:0]     TX_P_DATA
);

    //--------------------------------------------------
    // State encoding
    //--------------------------------------------------
    typedef enum logic [3:0] {
        IDLE        = 4'b0000,
        CMD         = 4'b0001,
        WR_ADDR     = 4'b0010,
        WR_DATA     = 4'b0011,
        RD_ADDR     = 4'b0100,
        CAP_A       = 4'b0101,
        CAP_B       = 4'b0110,
        CAP_FUN     = 4'b0111,
        FIFO_WR     = 4'b1000,
        FIFO_WR_LSB = 4'b1001,
        FIFO_WR_MSB = 4'b1010
    } state_t;

    //--------------------------------------------------
    // Internal registers
    //--------------------------------------------------
    state_t      current_state, next_state;

    logic [7:0]  CMD_IN;
    logic [15:0] DATA_OUT;     // holds RdData or ALU_OUT to transmit
    logic [3:0]  ADDRESS;      // latched address
    logic [3:0]  ALU_FUN_REG;  // registered ALU function (fix #4)

    //--------------------------------------------------
    // State register
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    //--------------------------------------------------
    // CMD_IN capture
    // Captured in IDLE when a valid byte arrives,
    // and updated in FIFO_WR / FIFO_WR_MSB for
    // back-to-back commands after a response.
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            CMD_IN <= 8'd0;
        else if (current_state == IDLE && RX_D_VLD)
            CMD_IN <= RX_P_Data;
        else if ((current_state == FIFO_WR || current_state == FIFO_WR_MSB) && RX_D_VLD)
            CMD_IN <= RX_P_Data;
    end

    //--------------------------------------------------
    // ADDRESS capture
    // Latched when a valid address byte arrives in
    // WR_ADDR or RD_ADDR.
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            ADDRESS <= 4'd0;
        else if ((next_state == WR_ADDR || next_state == RD_ADDR) && RX_D_VLD)
            ADDRESS <= RX_P_Data[3:0];
    end

    //--------------------------------------------------
    // DATA_OUT capture
    // Holds the value to be sent over TX FIFO.
    // Priority: RdData_Valid > OUT_Valid
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            DATA_OUT <= 16'd0;
        else if (RdData_Valid)
            DATA_OUT <= {8'd0, RdData};
        else if (OUT_Valid)
            DATA_OUT <= ALU_OUT;
    end

    //--------------------------------------------------
    // ALU_FUN_REG capture  (fix #4 — registered, not combinatorial)
    // Latched when the function byte arrives in CAP_FUN.
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            ALU_FUN_REG <= 4'd0;
        else if (current_state == CAP_FUN && RX_D_VLD)
            ALU_FUN_REG <= RX_P_Data[3:0];
    end

    //--------------------------------------------------
    // Next-state logic  (fixes #2 and #3)
    //--------------------------------------------------
    always_comb begin
        next_state = current_state;

        case (current_state)

            // Wait for first command byte
            IDLE: begin
                if (RX_D_VLD)
                    next_state = CMD;
            end

            CMD: begin
                if(RX_D_VLD) begin
                    case (CMD_IN)
                        8'hAA:   next_state = WR_ADDR;
                        8'hBB:   next_state = RD_ADDR;
                        8'hCC:   next_state = CAP_A;
                        8'hDD:   next_state = CAP_FUN;
                        default: next_state = IDLE;
                    endcase
                end
            end

            // Wait for address byte then data byte
            WR_ADDR: next_state = RX_D_VLD ? WR_DATA : WR_ADDR;

            // Stay until data byte arrives, then go IDLE (fix #3)
            WR_DATA: next_state = RX_D_VLD ? IDLE : WR_DATA;

            // Wait for address byte; move when RdData is valid and FIFO has space
            RD_ADDR: begin
                if (RX_D_VLD)
                    next_state = RD_ADDR;          // address just arrived, wait for read
                else if (RdData_Valid && !FIFO_FULL)
                    next_state = FIFO_WR;
            end

            // Wait for Operand A
            CAP_A: next_state = RX_D_VLD ? CAP_B : CAP_A;

            // Wait for Operand B
            CAP_B: next_state = RX_D_VLD ? CAP_FUN : CAP_B;

            // Wait for function byte, then wait for ALU result and FIFO space
            CAP_FUN: begin
                if (RX_D_VLD)
                    next_state = CAP_FUN;          // function just latched, wait for ALU
                else if (OUT_Valid && !FIFO_FULL)
                    next_state = FIFO_WR_LSB;
            end

            // After sending read result, accept next command or go IDLE
            FIFO_WR: begin
                next_state = RX_D_VLD ? CMD : IDLE;
            end

            // Send low byte of ALU result; immediately move to high byte
            FIFO_WR_LSB: next_state = FIFO_WR_MSB;

            // Send high byte of ALU result; accept next command or go IDLE
            FIFO_WR_MSB: begin
                next_state = RX_D_VLD ? CMD : IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    //--------------------------------------------------
    // Output logic  (fix #5 — FIFO_WR and FIFO_WR_LSB separated)
    //--------------------------------------------------
    always_comb begin
        // Safe defaults
        ALU_FUN    = ALU_FUN_REG;   // always drive from registered value
        WrEN       = 1'b0;
        clk_div_en = 1'b1;
        TX_D_VLD   = 1'b0;
        RdEn       = 1'b0;
        CLK_EN     = 1'b0;
        ALU_EN     = 1'b0;
        Address    = 4'd0;
        WrData     = 8'd0;
        TX_P_DATA  = 8'd0;

        case (current_state)

            // Write data into register file
            WR_DATA: begin
                Address = ADDRESS;
                WrEN    = 1'b1;
                WrData  = RX_P_Data;
            end

            // Issue read to register file using latched address (fix #6)
            RD_ADDR: begin
                Address = ADDRESS;
                RdEn    = 1'b1;
            end

            // Write Operand A into REG0
            CAP_A: begin
                Address = 4'd0;
                WrData  = RX_P_Data;
                WrEN    = 1'b1;
            end

            // Write Operand B into REG1
            CAP_B: begin
                Address = 4'd1;
                WrData  = RX_P_Data;
                WrEN    = 1'b1;
            end

            // Enable ALU and gate its clock
            CAP_FUN: begin
                ALU_EN = 1'b1;
                CLK_EN = 1'b1;
            end

            // Send read result (single byte) over TX FIFO (fix #5)
            FIFO_WR: begin
                CLK_EN    = 1'b1;
                TX_D_VLD  = 1'b1;
                TX_P_DATA = DATA_OUT[7:0];
            end

            // Send low byte of ALU result
            FIFO_WR_LSB: begin
                CLK_EN    = 1'b1;
                TX_D_VLD  = 1'b1;
                TX_P_DATA = DATA_OUT[7:0];
            end

            // Send high byte of ALU result
            FIFO_WR_MSB: begin
                CLK_EN    = 1'b0;
                TX_D_VLD  = 1'b1;
                TX_P_DATA = DATA_OUT[15:8];
            end

            default: ; // all outputs already set to defaults above
        endcase
    end

endmodule
