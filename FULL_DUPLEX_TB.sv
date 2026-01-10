import SYS_PKG::*;

module FULL_DUPLEX_TB;

    localparam CLK_PERIOD = 32;
    localparam PRESCALE   = 16;

    logic CLK, clk_mult ,RST;

    dataframe_t tx_data;
    logic        tx_data_valid;
    logic        PAR_EN, PAR_TYP;
    logic        TX_OUT;
    logic        Busy;

    logic        RX_IN;
    logic [5:0]  prescale;
    logic        rx_data_valid;
    dataframe_t  rx_data;
    logic        PARITY_ERROR, FRAME_ERROR;

    assign RX_IN = TX_OUT;

    always #(CLK_PERIOD/2) CLK = ~CLK;
    always #((CLK_PERIOD/(2*PRESCALE))) clk_mult = ~clk_mult;

    UART_TX TX (
        .CLK(CLK),
        .RST(RST),
        .P_DATA(tx_data),
        .DATA_VALID(tx_data_valid),
        .PAR_EN(PAR_EN),
        .PAR_TYP(PAR_TYP),
        .TX_OUT(TX_OUT),
        .Busy(Busy)
    );

    UART_RX RX (
        .CLK(clk_mult),
        .RST(RST),
        .RX_IN(RX_IN),
        .prescale(prescale),
        .PAR_TYP(PAR_TYP),
        .PAR_EN(PAR_EN),
        .data_valid(rx_data_valid),
        .P_DATA(rx_data),
        .PARITY_ERROR(PARITY_ERROR),
        .FRAME_ERROR(FRAME_ERROR)
    );


    task automatic send_byte(input dataframe_t data);
        begin
            @(posedge CLK);
            tx_data       = data;
            tx_data_valid = 1'b1;

            @(posedge CLK);
            tx_data_valid = 1'b0;

            wait (Busy == 0);
        end
    endtask



    initial begin
        CLK = 0;
        clk_mult = 0;
        RST = 0;
        tx_data = 0;
        tx_data_valid = 0;
        PAR_EN = 1;
        PAR_TYP = 0;
        prescale = PRESCALE;

        #100;
        RST = 1;

        send_byte(8'h55);
        send_byte(8'hA3);
        send_byte(8'hFF);
        send_byte(8'h00);
        PAR_TYP = 1;
        send_byte(8'h3C);

        $finish;
    end

endmodule