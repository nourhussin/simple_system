module ClkDiv
(
    input  logic        i_ref_clk,      
    input  logic        i_rst_n,       
    input  logic [7:0]  i_div_ratio,    
    input  logic        i_clk_en,       
    output logic        o_div_clk       
);

    logic        ClK_DIV_EN;      // Internal clock division enable
    logic [7:0]  half_ratio;     // Half of division ratio
    logic [7:0]  counter;        // Counter
    logic        out_div;

    // half ratio
    assign half_ratio = i_div_ratio >> 1;

    // enable only when ratio >= 2
    assign ClK_DIV_EN = i_clk_en && (i_div_ratio != 8'd0) && (i_div_ratio != 8'd1);

    //--------------------------------------------------
    // Clock divider
    //--------------------------------------------------
    always_ff @(posedge i_ref_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            out_div <= 1'b0;
            counter <= 8'd0;
        end
        else if (ClK_DIV_EN) begin
            counter <= counter + 8'd1;

            if (counter == 8'd0)
                out_div <= 1'b1;

            else if (counter == half_ratio)
                out_div <= ~out_div;

            else if (counter == i_div_ratio) begin
                out_div <= ~out_div;
                counter <= 8'd1;
            end
        end
    end

    // Bypass if disabled
    assign o_div_clk = ClK_DIV_EN ? out_div : i_ref_clk;

endmodule
