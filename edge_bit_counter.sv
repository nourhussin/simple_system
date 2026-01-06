module edge_bit_counter(
input logic CLK,
input logic RST,
input logic enable,
input logic [5:0] prescale,
output logic [3:0] bit_cnt,
output logic [5:0] edge_cnt
);

logic count_done;

/*-----------------------------------
  Bit Counter
-----------------------------------*/
always_ff @(posedge CLK or negedge RST) begin
    if(!RST)
        bit_cnt <= 4'd0;
    else if(enable) begin
        if(count_done)
            bit_cnt <= bit_cnt + 1'b1;
    end
    else
        bit_cnt <= 4'd0;
end

/*-----------------------------------
  Edge Counter
-----------------------------------*/
always_ff @(posedge CLK or negedge RST) begin
    if(!RST)
        edge_cnt <= 6'd0;
    else if(enable) begin
        if(count_done)
            edge_cnt <= 6'd0;
        else
            edge_cnt <= edge_cnt + 1'b1;
    end
    else
        edge_cnt <= 6'd0;
end

/*-----------------------------------
  Count Done Logic
-----------------------------------*/
assign count_done = (edge_cnt == prescale - 1'b1);

endmodule
