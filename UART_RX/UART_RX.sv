import SYS_PKG::*;

module UART_RX(
    input logic CLK,
    input logic RST,
    input logic RX_IN,
    input logic [5:0] prescale,
    input logic PAR_TYP,
    input logic PAR_EN,
    output logic data_valid,
    output dataframe_t P_DATA,
    output logic PARITY_ERROR, FRAME_ERROR
);

logic data_samp_en, enable, sampled_bit, deser_en;
logic stp_err, stp_chk_en, strt_glitch, strt_chk_en, par_err, par_chk_en;
logic [5:0] edge_cnt;
logic [3:0] bit_cnt;

strt_check U_strt_Check(
    .CLK(CLK),
    .RST(RST),
    .strt_chk_en(strt_chk_en),
    .sampled_bit(sampled_bit),
    .strt_glitch(strt_glitch)
);

stop_check U_stop_Check(
    .CLK(CLK),
    .RST(RST),
    .stp_chk_en(stp_chk_en),
    .sampled_bit(sampled_bit),
    .stp_err(stp_err)
);

parity_check U_parity_Check(
    .CLK(CLK),
    .RST(RST),
    .P_DATA(P_DATA),
    .par_chk_en(par_chk_en),
    .sampled_bit(sampled_bit),
    .PAR_TYP(PAR_TYP),
    .par_err(par_err)
);

FSM_RX U_FSM(
    .RX_IN(RX_IN),
    .bit_cnt(bit_cnt),
    .edge_cnt(edge_cnt),
    .PAR_EN(PAR_EN),
    .par_err(par_err),
    .strt_glitch(strt_glitch),
    .stp_err(stp_err),
    .CLK(CLK),
    .RST(RST),
    .data_samp_en(data_samp_en),
    .enable(enable),
    .deser_en(deser_en),
    .data_valid(data_valid),
    .stp_chk_en(stp_chk_en),
    .strt_chk_en(strt_chk_en),
    .par_chk_en(par_chk_en),
    .prescale(prescale),
    .FRAME_ERROR(FRAME_ERROR),
    .PARITY_ERROR(PARITY_ERROR)
);

edge_bit_counter U_edge_bit_counter(
    .CLK(CLK),
    .RST(RST),
    .enable(enable),
    .bit_cnt(bit_cnt),
    .edge_cnt(edge_cnt),
    .prescale(prescale)
);

deserializer U_deserializer(
    .CLK(CLK),
    .RST(RST),
    .deser_en(deser_en),
    .edge_cnt(edge_cnt),
    .prescale(prescale),
    .sampled_bit(sampled_bit),
    .P_DATA(P_DATA)
);

data_sampling U_data_sampling(
    .CLK(CLK),
    .RST(RST),
    .data_samp_en(data_samp_en),
    .edge_cnt(edge_cnt),
    .prescale(prescale),
    .RX_IN(RX_IN),
    .sampled_bit(sampled_bit)
);

endmodule
