import SYS_PKG::*;

module SYS_TOP #(
    parameter int OPERAND_WIDTH   = 8,
    parameter int ALU_OUT_WIDTH   = 16,
    parameter int DATA_WIDTH      = 8,
    parameter int RF_ADDR      = 4,
    parameter int PRESCALE_WIDTH  = 6,
    parameter int ALU_FUN_WIDTH   = 4
)(
    input  logic REF_CLK,
    input  logic RST_N,
    input  logic UART_CLK,
    input  logic UART_RX_IN,
    output logic UART_TX_O,
    output logic parity_error,
    output logic framing_error
);

    // ALU operands
    logic [OPERAND_WIDTH-1:0] Op_A, Op_B;
    logic [ALU_OUT_WIDTH-1:0] ALU_OUT;
    
    // Data and Address buses
    logic [DATA_WIDTH-1:0] Rd_D, Wr_D, WR_DATA;
    logic [RF_ADDR-1:0] Addr;
    
    // RX Data signals
    logic [DATA_WIDTH-1:0] SYNC_RX_DATA, ASYNC_RX_DATA;
    logic RX_OUT_V;
    
    // Clock dividers & ratios
    logic [DATA_WIDTH-1:0] Div_Ratio, UART_Config, RD_DATA;
    
    // ALU control
    logic [ALU_FUN_WIDTH-1:0] ALU_FUN;

    // Reset synchronization
    logic SYNC_RST_REF, SYNC_RST_UART;

    // Clocks
    logic RX_CLK, TX_CLK, ALU_CLK;

    // FIFO and control signals
    logic Gate_EN, F_EMPTY, BUSY, RD_INC, FIFO_FULL,TX_D_VLD, WR_INC;
    logic WrEn, WrEn_P, RdEn, Rd_D_VLD, EN, OUT_Valid;
    logic SYNC_RX_VLD;
    logic clk_div_en;

    ////////////// ASYNC_FIFO //////////////
    async_fifo  #(.width(DATA_WIDTH)) U_ASYNC_FIFO(
        .wclk    (REF_CLK),
        .wrst_n  (SYNC_RST_REF),
        .w_en    (WR_INC),
        .rclk    (TX_CLK),
        .rrst_n  (SYNC_RST_UART),
        .r_en    (RD_INC),
        .data_in (WR_DATA),
        .data_out(RD_DATA),
        .empty   (F_EMPTY),
        .full    (FIFO_FULL)
    );

    ////////////// SYS_CTRL //////////////
    SYS_CTRL U_SYS_CTRL (
        .CLK       (REF_CLK),
        .RST       (SYNC_RST_REF),
        .OUT_Valid (OUT_Valid),
        .RdData_Valid (Rd_D_VLD),
        .RX_D_VLD  (SYNC_RX_VLD),
        .ALU_OUT   (ALU_OUT),
        .RdData    (Rd_D),
        .RX_P_Data (SYNC_RX_DATA),
        .FIFO_FULL (FIFO_FULL),
        .ALU_FUN   (ALU_FUN),
        .WrEN      (WrEn),
        .clk_div_en(clk_div_en),
        .TX_D_VLD  (TX_D_VLD),
        .RdEn      (RdEn),
        .CLK_EN    (Gate_EN),
        .ALU_EN    (EN),
        .Address   (Addr),
        .WrData    (Wr_D),
        .TX_P_DATA (WR_DATA)
    );

    ////////////// REG_FILE //////////////
    RegFile U_RegFile (
        .WrEn          (WrEn_P),
        .RdEn          (RdEn),
        .CLK           (REF_CLK),
        .RST           (SYNC_RST_REF),
        .Address       (Addr),
        .WrData        (Wr_D),
        .RdData        (Rd_D),
        .REG0          (Op_A),
        .REG1          (Op_B),
        .REG2          (UART_Config),
        .REG3          (Div_Ratio),
        .RdData_Valid  (Rd_D_VLD)
    );

    ////////////// ALU //////////////
    ALU U_ALU (
        .CLK       (ALU_CLK),
        .RST       (SYNC_RST_REF),
        .A         (Op_A),
        .B         (Op_B),
        .ALU_FUN   (opcode_t'(ALU_FUN)),
        .Enable    (EN),
        .ALU_OUT   (ALU_OUT),
        .OUT_VALID (OUT_Valid)
    );

    ////////////// PULSE_GEN(RD_INC) //////////////
    PULSE_GEN U_PULSE_GEN0 (
        .CLK        (TX_CLK),
        .RST        (SYNC_RST_UART),
        .LVL_SIG         (BUSY),
        .PULSE_SIG  (RD_INC)
    );

    PULSE_GEN U_PULSE_GEN1 (
        .CLK        (REF_CLK),
        .RST        (SYNC_RST_REF),
        .LVL_SIG    (TX_D_VLD),
        .PULSE_SIG  (WR_INC)
    );

    ////////////// UART //////////////
    UART_TX TX (
        .CLK         (TX_CLK),
        .RST         (SYNC_RST_UART),
        .P_DATA      (RD_DATA),
        .DATA_VALID  (!F_EMPTY),
        .PAR_EN      (UART_Config[0]),
        .PAR_TYP     (UART_Config[1]),
        .TX_OUT      (UART_TX_O),
        .Busy        (BUSY)
    );
    UART_RX RX (
        .CLK            (RX_CLK),
        .RST            (SYNC_RST_UART),
        .RX_IN          (UART_RX_IN),
        .prescale       (UART_Config[7:2]),
        .PAR_TYP        (UART_Config[1]),
        .PAR_EN         (UART_Config[0]),
        .data_valid     (RX_OUT_V),
        .P_DATA         (ASYNC_RX_DATA),
        .PARITY_ERROR   (parity_error),
        .FRAME_ERROR    (framing_error)
    );

    ////////////// UART_DATA_SYNC //////////////
    Data_Sync VLD_DATA_SYNC (
        .dest_clk       (REF_CLK),
        .dest_rst       (SYNC_RST_REF),
        .unsync_bus(ASYNC_RX_DATA),
        .bus_enable(RX_OUT_V),
        .sync_bus  (SYNC_RX_DATA),
        .enable_pulse(SYNC_RX_VLD)
    );

    ////////////// RX_CLK_DIV //////////////
    ClkDiv RX_CLK_DIV (
        .i_ref_clk (UART_CLK),
        .i_rst_n  (SYNC_RST_UART),
        .i_div_ratio(Div_Ratio),
        .i_clk_en  (clk_div_en),
        .o_div_clk (RX_CLK)
    );

    ////////////// TX_CLK_DIV //////////////
    ClkDiv TX_CLK_DIV (
        .i_ref_clk (UART_CLK),
        .i_rst_n  (SYNC_RST_UART),
        .i_div_ratio({2'b00,UART_Config[7:2]}),
        .i_clk_en  (clk_div_en),
        .o_div_clk (TX_CLK)
    );

    ////////////// ALU_clock_gating //////////////
    CLK_GATE U_CLK_GATE (
        .CLK_EN    (Gate_EN),
        .CLK       (REF_CLK),
        .GATED_CLK (ALU_CLK)
    );

    ////////////// REF_RST_SYNC //////////////
    RST_SYNC REF_RST_SYNC (
        .CLK       (REF_CLK),
        .RST       (RST_N),
        .SYNC_RST  (SYNC_RST_REF)
    );

    ////////////// UART_RST_SYNC //////////////
    RST_SYNC UART_RST_SYNC (
        .CLK       (UART_CLK),
        .RST       (RST_N),
        .SYNC_RST  (SYNC_RST_UART)
    );

    ////////////// WrEn_PULSE_GEN //////////////
    PULSE_GEN WrEn_PULSE_GEN (
        .CLK        (REF_CLK),
        .RST        (SYNC_RST_REF),
        .LVL_SIG         (WrEn),
        .PULSE_SIG  (WrEn_P)
    );

endmodule
