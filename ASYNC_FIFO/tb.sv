module tb ;
    localparam wT = 10;
    localparam rT = 18;
    logic wclk = 0;
    logic rclk = 0;

    logic wrst_n, rrst_n;
    logic w_en, r_en;
    logic [31:0] data_in;

    logic full, empty;
    logic [31:0] data_out;

    async_fifo asf(
        .wclk(wclk) , .rclk(rclk),
        .wrst_n(wrst_n) , .rrst_n(rrst_n),
        .w_en(w_en) , .r_en(r_en),

        .data_in(data_in),
        .data_out(data_out),
        .full(full) , .empty(empty)
    );

    always#(wT/2) wclk = !wclk;
    always#(rT/2) rclk = !rclk;

    initial begin
        wrst_n = 0; rrst_n = 0;
        data_in = 0; r_en = 0; w_en = 0;
        #25;

        wrst_n = 1; rrst_n = 1;
        r_en = 1; 
        #25;

        w_en = 1; data_in = 40;
        #25;

        r_en = 0;
        data_in = 5;
        #100;

        w_en = 0; r_en = 1;
        #200;

        $finish;
    end

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb);
    end

endmodule