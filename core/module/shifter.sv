module shifter32 (
    input logic [31:0] i_data,
    input logic [4:0]  i_shamt,
    input logic i_right,
    input logic i_arith,

    output logic [31:0] o_data
);

    logic [31:0] stage0, stage1, stage2, stage4, stage8, stage16;
    logic [31:0] left1, left2, left4, left8, left16;
    logic [31:0] right1, right2, right4, right8, right16;
    logic [31:0] shift1, shift2, shift4, shift8, shift16;

    assign stage0 = i_data;

    assign left1 = {stage0[30:0], 1'b0};
    assign right1 = i_arith ? {stage0[31], stage0[31:1]} : {1'b0, stage0[31:1]};
    assign shift1 = i_right ? right1 : left1;
    assign stage1 = (i_shamt[0]) ? shift1 : stage0;

    assign left2 = {stage1[29:0], 2'b00};
    assign right2 = i_arith ? {2{stage1[31]}, stage1[31:2]} : {2'b00, stage1[31:2]};
    assign shift2 = i_right ? right2 : left2;
    assign stage2 = (i_shamt[1]) ? shift2 : stage1;

    assign left4 = {stage2[27:0], 4'b0000};
    assign right4 = i_arith ? {4{stage2[31]}, stage2[31:4]} : {4'b0000, stage2[31:4]};
    assign shift4 = i_right ? right4 : left4;   
    assign stage4 = (i_shamt[2]) ? shift4 : stage2;

    assign left8 = {stage4[23:0], 8'b00000000};
    assign right8 = i_arith ? {8{stage4[31]}, stage4[31:8]} : {8'b00000000, stage4[31:8]};
    assign shift8 = i_right ? right8 : left8;
    assign stage8 = (i_shamt[3]) ? shift8 : stage4;

    assign left16 = {stage8[15:0], 16'b0000000000000000};
    assign right16 = i_arith ? {16{stage8[31]}, stage8[31:16]} : {16'b0000000000000000, stage8[31:16]};
    assign shift16 = i_right ? right16 : left16;
    assign stage16 = (i_shamt[4]) ? shift16 : stage8;   

    assign o_data = stage16;

endmodule