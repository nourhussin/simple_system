module deserializer(
    input  logic       CLK,
    input  logic       RST,
    input  logic       deser_en,
    input  logic [5:0] edge_cnt,
    input  logic [5:0] prescale,
    input  logic       sampled_bit,
    output logic [7:0] P_DATA
);

logic [2:0] bit_index; // counts bits from 0 to 7
logic latch_bit;

// Decide when to latch a new bit (at the end of each bit period)
assign latch_bit = deser_en && (edge_cnt == prescale - 1);

always_ff @(posedge CLK or negedge RST) begin
    if (!RST) begin
        P_DATA    <= 8'd0;
        bit_index <= 3'd0;
    end
    else if(latch_bit) begin
        P_DATA <= {sampled_bit, P_DATA[7:1]}; // shift in new bit
        if (bit_index < 3'd7)
            bit_index <= bit_index + 1;
        else
            bit_index <= 3'd0; // reset after 8 bits
    end
end

endmodule
