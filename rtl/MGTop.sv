module MGTop
#(
    parameter IP_CHANNEL_WIDTH = 1080,
    parameter OP_CHANNEL_WIDTH = 20,
    parameter stepSel0 = 16,   //=320/OP_CHANNEL_WIDTH 
    parameter stepSel1 = 32,   //=640/OP_CHANNEL_WIDTH
    parameter stepSel2 = 54   //=1080/OP_CHANNEL_WIDTH
)
(
    input clk,                          // Clock
    input clk_en,                       // Clock Enable
    input rst_n,                        // Asynchronous reset active low

    // Pattern Input passed through the micro-processor
    input [4:0] pattern_w,              // size of the pattern W / "Repeated Pattern" width: 5 (XXX00) to 8 (XXX11)
    input pattern,                      // Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
    input [7:0] repeatedPattern,        // pattern, to be repeated
    input load_pattern,                 // to load the pattern for repetition

    input [1:0] mask_type,              // Type of masks sliding right 00 - sliding left 01 - Random Mask 10 - repeated Pattern 11
    input  next,

    output logic [OP_CHANNEL_WIDTH-1:0] DOUT
    );

    logic [0:639] mg_mask;       // Mask Generated
    logic rp_valid;               // Valid signal for the output

    logic  [IP_CHANNEL_WIDTH-1:0] DIN;
    logic  load;
    logic  [1:0] imageResolution;

    mask_generation_VGA MGWrapper (.*);
    mask_serializer #(IP_CHANNEL_WIDTH,OP_CHANNEL_WIDTH,stepSel0,stepSel1,stepSel2) SerialInterface (.DIN(DIN),.clk(clk),.next(next),.load(load),.imageResolution(imageResolution),.DOUT(DOUT));


    assign DIN = mg_mask;
    assign load = rp_valid;
    assign imageResolution = 2'b01;


endmodule

