module strt_check(
  input logic CLK,
  input logic RST,
  input logic strt_chk_en,
  input logic sampled_bit,
  output logic strt_glitch
);

always_ff @(posedge CLK or negedge RST) begin
    if(!RST)
        strt_glitch <= 1'b0;
    else if(strt_chk_en)
        strt_glitch <= sampled_bit;
end

endmodule
