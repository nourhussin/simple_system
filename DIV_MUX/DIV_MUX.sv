module DIV_MUX
(
  input logic  [5:0] prescale ,
  output logic  [7:0] RX_div_ratio 
);

always_comb
 begin
    //  RX_div_ratio <= 8'd32 / prescale;
    //will use case statment to minimize number of dviders in the system to reduce area and power
     case(prescale)
     
      6'd32    : RX_div_ratio = 1'd1  ;
      6'd16    : RX_div_ratio = 1'd2  ;
      6'd8     : RX_div_ratio = 1'd4  ;
      6'd4     : RX_div_ratio = 1'd8  ;
      6'd2     : RX_div_ratio = 1'd16 ;
     default   : RX_div_ratio = 1'd1  ;

    endcase
 end

endmodule
