import SYS_PKG::*;

module UART_TX (
    input CLK, RST,

    input dataframe_t P_DATA,
    input DATA_VALID,

    input PAR_EN,  // 1 enable parity
    input PAR_TYP, // 0 even, 1 odd

    output logic TX_OUT,
    output logic Busy // for system controller
);


enum logic [2:0] {IDLE, WAIT, START, SERIAL, PARITY, ENDD} current_state, next_state;
logic [2:0] counter;
logic [7:0] shift_reg;
logic serial_bit, parity_bit;

assign parity_bit = ^{PAR_TYP,P_DATA};
assign serial_bit = shift_reg[0];

//---------------- State Register ---------------------
always_ff @(posedge CLK or negedge RST) begin
    if (!RST) begin
        current_state <= IDLE;
        counter       <= 0;
        shift_reg     <= 0;
    end else begin
        current_state <= next_state;

        if (current_state == START) begin
            shift_reg <= P_DATA;
            counter   <= 0;
        end
        else if (current_state == SERIAL) begin
            shift_reg <= shift_reg >> 1;
            counter   <= counter + 1;
        end
    end
end

//---------------- Next State Logic ----------------
always@(*) begin
    next_state = current_state;

    case (current_state)
        IDLE: begin
            if (DATA_VALID)
                next_state = WAIT;
        end

        WAIT: begin
            next_state = START;
        end

        START: begin
            next_state = SERIAL;
        end

        SERIAL: begin
            if (counter == 3'd7)
                next_state = PAR_EN ? PARITY : ENDD;
        end

        PARITY: begin
            next_state = ENDD;
        end

        ENDD: begin
            next_state = IDLE;
        end

        default: next_state = IDLE;
    endcase
end

//-------------------- Output logic -----------
always @(*) begin
    case(current_state)
    IDLE: begin
        TX_OUT = 1;
        Busy = 0;
    end

    WAIT: begin
        TX_OUT = 1;
        Busy = 0;
    end

    START: begin
        TX_OUT = 0;
        Busy = 1;
    end

    SERIAL: begin
        TX_OUT = serial_bit;
        Busy = 1;
    end

    PARITY: begin
        TX_OUT = parity_bit;
        Busy = 1;
    end

    ENDD: begin
        TX_OUT = 1;
        Busy = 1;
    end

    default: begin
        TX_OUT = 1;
        Busy = 0;
    end
    endcase
end

endmodule