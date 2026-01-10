module data_sampling(
  input logic CLK,
  input logic RST,
  input logic data_samp_en,
  input logic [5:0] edge_cnt,
  input logic [5:0] prescale,
  input logic RX_IN,
  output logic sampled_bit
);

logic [2:0] sample;
logic [5:0] mid_bit;
logic [5:0] mid_bit_after;
logic [5:0] mid_bit_before;

/*-----------------------------------
  Mid-bit calculation
-----------------------------------*/
assign mid_bit        = (prescale >> 1) - 1'b1;
assign mid_bit_after  = mid_bit + 1'b1;
assign mid_bit_before = mid_bit - 1'b1;

/*-----------------------------------
  Take 3 samples around mid-bit
-----------------------------------*/
always_ff @(posedge CLK or negedge RST) begin
    if(!RST)
        sample <= 3'd0;
    else if(data_samp_en) begin
        if(edge_cnt == mid_bit_before)
            sample[0] <= RX_IN;
        if(edge_cnt == mid_bit)
            sample[1] <= RX_IN;
        if(edge_cnt == mid_bit_after)
            sample[2] <= RX_IN;
    end
    else
        sample <= 3'd0;
end

/*-----------------------------------
  Majority vote
-----------------------------------*/
always_ff @(posedge CLK or negedge RST) begin
    if(!RST)
        sampled_bit <= 1'b0;
    else if(data_samp_en)
        sampled_bit <= (sample[0] & sample[1]) |
                       (sample[1] & sample[2]) |
                       (sample[0] & sample[2]);
    else
        sampled_bit <= 1'b1;
end

endmodule
