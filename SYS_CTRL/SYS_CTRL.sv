/*
 * Module  : SYS_CTRL
 * Purpose : System controller FSM that decodes UART commands and orchestrates
 *           the register file, ALU, clock gating, and TX FIFO.
 *
 * Supported Commands (received via UART RX):
 *   0xAA  Write  – followed by: [ADDR] [DATA]
 *   0xBB  Read   – followed by: [ADDR]  → response sent over TX
 *   0xCC  ALU with new operands – followed by: [OP_A] [OP_B] [FUNC]
 *   0xDD  ALU with existing operands – followed by: [FUNC]
 *
 * TX response:
 *   Read  → 1 byte  (register value)
 *   ALU   → 2 bytes (LSB first, then MSB of 16-bit result)
 */

module SYS_CTRL
(
    input  logic           CLK,
    input  logic           RST,           // Active-low asynchronous reset

    // Status inputs
    input  logic           OUT_Valid,     // ALU result is ready
    input  logic           RdData_Valid,  // Register file read data is ready
    input  logic           RX_D_VLD,     // New byte available from UART RX
    input  logic           FIFO_FULL,    // TX FIFO cannot accept more data

    // Data inputs
    input  logic [15:0]    ALU_OUT,      // 16-bit ALU result
    input  logic [7:0]     RdData,       // Register file read data
    input  logic [7:0]     RX_P_Data,    // Parallel data from UART RX

    // Register file interface
    output logic           WrEN,         // Write enable to register file
    output logic           RdEn,         // Read enable to register file
    output logic [3:0]     Address,      // Register address
    output logic [7:0]     WrData,       // Data to write into register file

    // ALU interface
    output logic [3:0]     ALU_FUN,      // ALU operation select
    output logic           ALU_EN,       // ALU enable
    output logic           CLK_EN,       // ALU clock gate enable

    // TX FIFO interface
    output logic           TX_D_VLD,     // Data valid — write to TX FIFO
    output logic [7:0]     TX_P_DATA,    // Byte to send over UART TX

    // Clock divider enable
    output logic           clk_div_en    // Enable signal for RX clock divider
);

    // =========================================================
    // State encoding
    // =========================================================
    typedef enum logic [3:0] {
        IDLE        = 4'b0000,  // Wait for a command byte
        CMD         = 4'b0001,  // Decode the received command
        WR_ADDR     = 4'b0010,  // Wait for write address byte
        WR_DATA     = 4'b0011,  // Wait for write data byte, then write
        RD_ADDR     = 4'b0100,  // Wait for read address, then issue read
        CAP_A       = 4'b0101,  // Capture operand A into REG0
        CAP_B       = 4'b0110,  // Capture operand B into REG1
        CAP_FUN     = 4'b0111,  // Capture ALU function, enable ALU, wait for result
        FIFO_WR     = 4'b1000,  // Push read result (1 byte) into TX FIFO
        FIFO_WR_LSB = 4'b1001,  // Push ALU result low byte into TX FIFO
        FIFO_WR_MSB = 4'b1010   // Push ALU result high byte into TX FIFO
    } state_t;

    // =========================================================
    // Internal signals
    // =========================================================
    state_t      current_state, next_state;

    logic [7:0]  CMD_IN;       // Latched command byte
    logic [3:0]  ADDRESS;      // Latched register address
    logic [15:0] DATA_OUT;     // Latched read data or ALU result for TX
    logic [3:0]  ALU_FUN_REG;  // Registered ALU function code

    // =========================================================
    // State register
    // =========================================================
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // =========================================================
    // Command latch
    // Captured when a valid byte arrives in IDLE.
    // Also updated in FIFO_WR / FIFO_WR_MSB to support
    // back-to-back commands immediately after a TX response.
    // =========================================================
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            CMD_IN <= 8'd0;
        else if (current_state == IDLE && RX_D_VLD)
            CMD_IN <= RX_P_Data;
        else if ((current_state == FIFO_WR || current_state == FIFO_WR_MSB) && RX_D_VLD)
            CMD_IN <= RX_P_Data;
    end

    // =========================================================
    // Address latch
    // Captured when a valid address byte arrives while already
    // sitting in WR_ADDR or RD_ADDR.
    // =========================================================
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            ADDRESS <= 4'd0;
        else if ((current_state == WR_ADDR || current_state == RD_ADDR) && RX_D_VLD)
            ADDRESS <= RX_P_Data[3:0];
    end

    // =========================================================
    // TX data latch
    // Holds the value that will be streamed out via the TX FIFO.
    // RdData_Valid takes priority over OUT_Valid.
    // =========================================================
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            DATA_OUT <= 16'd0;
        else if (RdData_Valid)
            DATA_OUT <= {8'd0, RdData};
        else if (OUT_Valid)
            DATA_OUT <= ALU_OUT;
    end

    // =========================================================
    // ALU function latch
    // Registered to avoid combinatorial glitches on ALU_FUN.
    // Captured when the function byte arrives in CAP_FUN.
    // =========================================================
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST)
            ALU_FUN_REG <= 4'd0;
        else if (current_state == CAP_FUN && RX_D_VLD)
            ALU_FUN_REG <= RX_P_Data[3:0];
    end

    // =========================================================
    // Next-state logic
    // =========================================================
    always_comb begin
        next_state = current_state; // Default: hold current state

        case (current_state)

            // --------------------------------------------------
            // IDLE: wait for the first command byte
            // --------------------------------------------------
            IDLE: begin
                if (RX_D_VLD)
                    next_state = CMD;
            end

            // --------------------------------------------------
            // CMD: CMD_IN is already latched from IDLE —
            // decode immediately, no extra RX_D_VLD needed
            // --------------------------------------------------
            CMD: begin
                case (CMD_IN)
                    8'hAA:   next_state = WR_ADDR;
                    8'hBB:   next_state = RD_ADDR;
                    8'hCC:   next_state = CAP_A;
                    8'hDD:   next_state = CAP_FUN;
                    default: next_state = IDLE;
                endcase
            end

            // --------------------------------------------------
            // WR_ADDR: wait for the address byte
            // --------------------------------------------------
            WR_ADDR: begin
                if (RX_D_VLD)
                    next_state = WR_DATA;
            end

            // --------------------------------------------------
            // WR_DATA: wait for the data byte, then go idle
            // --------------------------------------------------
            WR_DATA: begin
                if (RX_D_VLD)
                    next_state = IDLE;
            end

            // --------------------------------------------------
            // RD_ADDR: address is latched on RX_D_VLD;
            // wait until register file has valid data
            // and TX FIFO has space before transmitting
            // --------------------------------------------------
            RD_ADDR: begin
                if (RdData_Valid && !FIFO_FULL)
                    next_state = FIFO_WR;
            end

            // --------------------------------------------------
            // CAP_A: wait for operand A byte
            // --------------------------------------------------
            CAP_A: begin
                if (RX_D_VLD)
                    next_state = CAP_B;
            end

            // --------------------------------------------------
            // CAP_B: wait for operand B byte
            // --------------------------------------------------
            CAP_B: begin
                if (RX_D_VLD)
                    next_state = CAP_FUN;
            end

            // --------------------------------------------------
            // CAP_FUN: function byte is latched; ALU is enabled.
            // Wait until ALU produces a valid result and
            // TX FIFO has space before transmitting.
            // --------------------------------------------------
            CAP_FUN: begin
                if (OUT_Valid && !FIFO_FULL)
                    next_state = FIFO_WR_LSB;
            end

            // --------------------------------------------------
            // FIFO_WR: read result byte has been pushed.
            // Accept next command if one arrives, else go idle.
            // --------------------------------------------------
            FIFO_WR: begin
                next_state = RX_D_VLD ? CMD : IDLE;
            end

            // --------------------------------------------------
            // FIFO_WR_LSB: ALU low byte pushed;
            // move immediately to send the high byte
            // --------------------------------------------------
            FIFO_WR_LSB: begin
                next_state = FIFO_WR_MSB;
            end

            // --------------------------------------------------
            // FIFO_WR_MSB: ALU high byte pushed.
            // Accept next command if one arrives, else go idle.
            // --------------------------------------------------
            FIFO_WR_MSB: begin
                next_state = RX_D_VLD ? CMD : IDLE;
            end

            default: next_state = IDLE;

        endcase
    end

    // =========================================================
    // Output logic (Moore-style; ALU_FUN always from register)
    // =========================================================
    always_comb begin
        // ------ Safe defaults for all outputs ------
        ALU_FUN    = ALU_FUN_REG; // Driven from registered value — glitch-free
        WrEN       = 1'b0;
        clk_div_en = 1'b1;        // Clock divider kept enabled by default
        TX_D_VLD   = 1'b0;
        RdEn       = 1'b0;
        CLK_EN     = 1'b0;
        ALU_EN     = 1'b0;
        Address    = 4'd0;
        WrData     = 8'd0;
        TX_P_DATA  = 8'd0;

        case (current_state)

            // --------------------------------------------------
            // WR_DATA: drive address and data to register file;
            // assert write enable for one cycle
            // --------------------------------------------------
            WR_DATA: begin
                Address = ADDRESS;
                WrEN    = 1'b1;
                WrData  = RX_P_Data;
            end

            // --------------------------------------------------
            // RD_ADDR: drive latched address and assert read
            // enable so the register file begins the read
            // --------------------------------------------------
            RD_ADDR: begin
                Address = ADDRESS;
                RdEn    = 1'b1;
            end

            // --------------------------------------------------
            // CAP_A: write incoming byte into REG0 (operand A)
            // --------------------------------------------------
            CAP_A: begin
                Address = 4'd0;
                WrData  = RX_P_Data;
                WrEN    = 1'b1;
            end

            // --------------------------------------------------
            // CAP_B: write incoming byte into REG1 (operand B)
            // --------------------------------------------------
            CAP_B: begin
                Address = 4'd1;
                WrData  = RX_P_Data;
                WrEN    = 1'b1;
            end

            // --------------------------------------------------
            // CAP_FUN: enable ALU and its gated clock while
            // waiting for the result
            // --------------------------------------------------
            CAP_FUN: begin
                ALU_EN = 1'b1;
                CLK_EN = 1'b1;
            end

            // --------------------------------------------------
            // FIFO_WR: push the single read-result byte to TX
            // --------------------------------------------------
            FIFO_WR: begin
                CLK_EN    = 1'b1;
                TX_D_VLD  = 1'b1;
                TX_P_DATA = DATA_OUT[7:0];
            end

            // --------------------------------------------------
            // FIFO_WR_LSB: push low byte of ALU result to TX
            // --------------------------------------------------
            FIFO_WR_LSB: begin
                CLK_EN    = 1'b1;
                TX_D_VLD  = 1'b1;
                TX_P_DATA = DATA_OUT[7:0];
            end

            // --------------------------------------------------
            // FIFO_WR_MSB: push high byte of ALU result to TX.
            // De-assert CLK_EN — ALU clock no longer needed.
            // --------------------------------------------------
            FIFO_WR_MSB: begin
                CLK_EN    = 1'b0;
                TX_D_VLD  = 1'b1;
                TX_P_DATA = DATA_OUT[15:8];
            end

            // All other states use the defaults set above
            default: ;

        endcase
    end

endmodule