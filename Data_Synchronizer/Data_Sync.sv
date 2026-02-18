module Data_Sync
#(
    parameter int BUS_WIDTH  = 8,
    parameter int NUM_STAGES = 2
)
(
    input  logic                    dest_clk,
    input  logic                    dest_rst,           // async active-low
    input  logic                    bus_enable,
    input  logic [BUS_WIDTH-1:0]    unsync_bus,
    output logic [BUS_WIDTH-1:0]    sync_bus,
    output logic                    enable_pulse
);

    // Multi-stage synchronizer per bit
    logic [NUM_STAGES:0] sync_reg [BUS_WIDTH];

    logic [BUS_WIDTH-1:0] flops_out;
    logic [BUS_WIDTH-1:0] flops_pre_out;
    logic [BUS_WIDTH-1:0] generated_enable;

    integer I;

    // Rising-edge detect on synchronized enable
    assign generated_enable = (~flops_out) & flops_pre_out;

    //--------------------------------------------------
    // Sequential logic
    //--------------------------------------------------
    always_ff @(posedge dest_clk or negedge dest_rst) begin
        if (!dest_rst) begin
            sync_bus     <= '0;
            enable_pulse <= 1'b0;
            for (I=0; I<BUS_WIDTH; I++)
                sync_reg[I] <= '0;
        end
        else begin
            enable_pulse <= &generated_enable;

            // Synchronize enable through shift-register per bit
            for (I=0; I<BUS_WIDTH; I++)
                sync_reg[I] <= {bus_enable, sync_reg[I][NUM_STAGES:1]};

            // Latch bus only when all bits are synchronized
            if (&generated_enable)
                sync_bus <= unsync_bus;
        end
    end

    //--------------------------------------------------
    // Extract synchronizer taps
    //--------------------------------------------------
    genvar K;
    generate
        for (K=0; K<BUS_WIDTH; K++) begin
            assign flops_out[K]     = sync_reg[K][0];
            assign flops_pre_out[K] = sync_reg[K][1];
        end
    endgenerate

endmodule
