import SYS_PKG::*;

module parity_check(
  input logic CLK,
  input logic RST,
  input logic par_chk_en,
  input logic sampled_bit,
  input logic PAR_TYP,
  input dataframe_t P_DATA,
  output logic par_err
);

logic parity;

assign parity = PAR_TYP ? ~^P_DATA : ^P_DATA;

always_ff @(posedge CLK or negedge RST) begin
    if(!RST)
        par_err <= 1'b0;
    else if(par_chk_en)
        par_err <= (parity != sampled_bit);
end

endmodule
