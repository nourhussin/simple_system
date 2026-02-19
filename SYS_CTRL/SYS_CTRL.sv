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
    output logic           CLK_EN,     // ALU_CLK (gated)
    output logic           ALU_EN,
    output logic [3:0]     Address,
    output logic [7:0]     WrData,
    output logic [7:0]     TX_P_DATA
);

    //--------------------------------------------------
    // Internal registers
    //--------------------------------------------------
    logic [7:0]  CMD_IN;
    logic [3:0]  current_state, next_state;
    logic [15:0] DATA_OUT;      // hold read data or ALU_OUT
    logic [3:0]  ADDRESS;       // hold address to send in write state
    logic        write_done;    // handle WrEN signal

    //--------------------------------------------------
    // State encoding
    //--------------------------------------------------
    typedef enum logic [3:0] {
        // State	                    Action/Output	       Next State Conditions
        IDLE        = 4'b0000,   // 	Wait for command	   RX_D_VLD -> CMD
        CMD         = 4'b0001,   //     Decode command         Based on CMD_IN
        WR_ADDR     = 4'b0010,   //     Wait for W Addr        RX_D_VLD -> WR_DATA
        WR_DATA     = 4'b0011,   //     Write Data             write_don -> IDLE
        RD_ADDR     = 4'b0100,   //     Read Data              RdData_Valid & !FIFO_FULL -> FIFO_WR
        CAP_A       = 4'b0101,   //     Capture RX Data        RX_D_VLD -> next capture
        CAP_B       = 4'b0110,   //     Capture RX Data        RX_D_VLD -> next capture
        CAP_FUN     = 4'b0111,   //     Capture ALU function   write_done & !FIFO_FULL -> FIFO_WR_LSB
        FIFO_WR     = 4'b1000,   //     Send FIFO Data         RX_D_VLD -> CMD (else IDLE)
        FIFO_WR_LSB = 4'b1001,   //     Send Lower Byte        -> FIFO_WR_MSB
        FIFO_WR_MSB = 4'b1010    //     Send Upper Byte        RX_D_VLD -> CMD (else IDLE)
    } state_t;

    //--------------------------------------------------
    // Registers for sequential logic
    //--------------------------------------------------
    always_ff @(posedge CLK or negedge RST) begin
        if (!RST) begin
            ADDRESS     <= 4'd0;
            DATA_OUT    <= 16'd0;
            write_done  <= 1'b0;
        end else begin
            // Update write_done
            if (RX_D_VLD || next_state == CAP_B)
                write_done <= 1'b0;
            else if ((current_state == WR_DATA) || (current_state == CAP_A) 
                  || (current_state == CAP_B) || (current_state == CAP_FUN))
                write_done <= 1'b1;

            // Capture address
            if ((current_state == WR_ADDR || current_state == RD_ADDR) && RX_D_VLD)
                ADDRESS <= RX_P_Data;

            // Capture data
            if (RdData_Valid)
                DATA_OUT <= {8'd0, RdData};
            else if (OUT_Valid)
                DATA_OUT <= ALU_OUT;
        end
    end

    always_ff @(posedge CLK or negedge RST) begin
    if (!RST)
        CMD_IN <= 8'd0;
    else if (current_state == IDLE && RX_D_VLD)
        CMD_IN <= RX_P_Data;
    else if ((current_state == FIFO_WR || current_state == FIFO_WR_MSB) && RX_D_VLD)
        CMD_IN <= RX_P_Data;
    end

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
    // Next-state logic
    //--------------------------------------------------
    always_comb begin
        // Default assignments
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (RX_D_VLD) begin
                    next_state = CMD;
                end
            end

            CMD: begin
                case (CMD_IN)
                    8'hAA: next_state = RX_D_VLD ? WR_ADDR : CMD; // Write
                    8'hBB: next_state = RX_D_VLD ? RD_ADDR : CMD; // Read
                    8'hCC: next_state = RX_D_VLD ? CAP_A   : CMD; // Capture Inputs
                    8'hDD: next_state = RX_D_VLD ? CAP_FUN : CMD; // Capture Operation
                    default: next_state = IDLE;
                endcase
            end

            WR_ADDR: next_state = RX_D_VLD ? WR_DATA : WR_ADDR;
            WR_DATA: next_state = write_done ? IDLE : WR_DATA;
            RD_ADDR: next_state = (RdData_Valid && !FIFO_FULL) ? FIFO_WR : RD_ADDR;
            CAP_A  : next_state = RX_D_VLD ? CAP_B : CAP_A;
            CAP_B  : next_state = RX_D_VLD ? CAP_FUN : CAP_B;
            CAP_FUN: next_state = (!FIFO_FULL && write_done) ? FIFO_WR_LSB : CAP_FUN;
            FIFO_WR: begin
                next_state = RX_D_VLD ? CMD : IDLE;
            end
            FIFO_WR_LSB: next_state = FIFO_WR_MSB;
            FIFO_WR_MSB: begin
                next_state = RX_D_VLD ? CMD : IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    //--------------------------------------------------
    // Output logic
    //--------------------------------------------------
    always @(*) begin
        // Defaults
        ALU_FUN    = {4{1'b1}};
        WrEN       = 1'b0;
        clk_div_en = 1'b1;
        TX_D_VLD   = 1'b0;
        RdEn       = 1'b0;
        CLK_EN     = 1'b0;
        ALU_EN     = 1'b0;
        Address    = 4'd0;
        WrData     = {8{1'b0}};
        TX_P_DATA  = {8{1'b0}};

        case (current_state)
            WR_DATA: begin
                Address = ADDRESS;
                WrEN    = 1'b1;
                WrData  = RX_P_Data;
            end

            RD_ADDR: begin
                Address = ADDRESS;
                RdEn    = 1'b1;
            end

            CAP_A: begin
                Address = 4'd0;
                WrData  = RX_P_Data;
                WrEN    = write_done ? 1'b0 : 1'b1;
            end

            CAP_B: begin
                Address = 4'd1;
                WrData  = RX_P_Data;
                WrEN    = write_done ? 1'b0 : 1'b1;
            end

            CAP_FUN: begin
                ALU_EN  = 1'b1;
                ALU_FUN = RX_P_Data[3:0];
                CLK_EN  = 1'b1;
            end

            FIFO_WR, FIFO_WR_LSB: begin
                ALU_EN    = 1'b0;
                CLK_EN    = 1'b1;
                TX_D_VLD  = 1'b1;
                TX_P_DATA = DATA_OUT[7:0];
            end

            FIFO_WR_MSB: begin
                TX_P_DATA = DATA_OUT[15:8];
                ALU_EN    = 1'b0;
                CLK_EN    = 1'b0;
                TX_D_VLD  = 1'b1;
            end
        endcase
    end

endmodule
