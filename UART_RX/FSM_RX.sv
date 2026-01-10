module FSM_RX(
  input logic RX_IN,
  input logic [3:0] bit_cnt,
  input logic [5:0] edge_cnt,
  input logic [5:0] prescale,
  input logic PAR_EN,
  input logic par_err,
  input logic strt_glitch,
  input logic stp_err,
  input logic CLK,
  input logic RST,
  output logic data_samp_en,
  output logic enable,
  output logic deser_en,
  output logic data_valid,
  output logic stp_chk_en,
  output logic strt_chk_en,
  output logic par_chk_en,
  output logic FRAME_ERROR, PARITY_ERROR
);
  typedef enum logic [2:0] {
    IDLE  = 3'b000,
    STRT  = 3'b001,
    DATA  = 3'b011,
    PAR   = 3'b010,
    STP   = 3'b110,
    OUT   = 3'b111
  } state_t;

  state_t current_state, next_state;
  logic frame_error, parity_error;
  logic [5:0] count_done;

  assign count_done = prescale - 6'd1;

  always_ff @(posedge CLK or negedge RST) begin
    if (!RST) begin
      current_state <= IDLE;
      FRAME_ERROR   <= 1'b0;
      PARITY_ERROR  <= 1'b0;
    end else begin
      current_state <= next_state;
      FRAME_ERROR   <= frame_error;
      PARITY_ERROR  <= parity_error;
    end
  end

  always_comb begin
    case (current_state)
      IDLE: next_state = (!RX_IN) ? STRT : IDLE;

      STRT: next_state = (bit_cnt == 4'd0 && edge_cnt == count_done) ? (!strt_glitch ? DATA : IDLE) : STRT;

      DATA: next_state = (bit_cnt == 4'd8 && edge_cnt == count_done) ? (PAR_EN ? PAR : STP) : DATA;

      PAR: next_state = (bit_cnt == 4'd9 && edge_cnt == count_done) ? STP : PAR;

      STP: next_state = ((bit_cnt == 4'd10 && edge_cnt == count_done - 1 && PAR_EN) || (bit_cnt == 4'd9  && edge_cnt == count_done - 1 && !PAR_EN)) ? OUT : STP;

      OUT: next_state = (!RX_IN) ? STRT : IDLE;

      default: next_state = IDLE;
    endcase
  end

  always_comb begin
    data_samp_en = 1'b0;
    enable       = 1'b0;
    deser_en     = 1'b0;
    data_valid   = 1'b0;
    stp_chk_en   = 1'b0;
    strt_chk_en  = 1'b0;
    par_chk_en   = 1'b0;
    parity_error = 1'b0;
    frame_error  = 1'b0;

    case (current_state)
      IDLE: begin
        if (!RX_IN) begin
          data_samp_en  = 1'b1;
          enable        = 1'b1;
          strt_chk_en   = 1'b1;
        end
      end

      STRT: begin
        data_samp_en = 1'b1;
        enable       = 1'b1;
        strt_chk_en  = 1'b1;
      end

      DATA: begin
        data_samp_en = 1'b1;
        enable       = 1'b1;
        deser_en     = 1'b1;
      end

      PAR: begin
        data_samp_en = 1'b1;
        enable       = 1'b1;
        par_chk_en   = 1'b1;
      end

      STP: begin
        data_samp_en = 1'b1;
        enable       = 1'b1;
        stp_chk_en   = 1'b1;
      end

      OUT: begin
        data_samp_en = 1'b1;
        parity_error = par_err;
        frame_error = stp_err;
        data_valid   = ~(par_err || stp_err);
      end
    endcase
  end

endmodule
