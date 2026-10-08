module shifter32 (
    input logic [31:0] i_data,
    input logic [4:0]  i_shamt,
    input logic [1:0]  i_mode,

    output logic [31:0] o_data
);
    logic is_right, is_arith, is_valid;

    assign is_right = ~i_mode[0];
    assign is_arith = i_mode[1] & (~i_mode[0]);
    assign is_valid = ~(i_mode[1] & i_mode[0]);

    logic [31:0] stage0, stage1, stage2, stage4, stage8, stage16;
    logic [31:0] left1, left2, left4, left8, left16;
    logic [31:0] right1, right2, right4, right8, right16;
    logic [31:0] shift1, shift2, shift4, shift8, shift16;

    assign stage0 = i_data;

    assign left1 = {stage0[30:0], 1'b0};
    assign right1 = is_arith ? {stage0[31], stage0[31:1]} : {1'b0, stage0[31:1]};
    assign shift1 = is_right ? right1 : left1;
    assign stage1 = (i_shamt[0]) ? shift1 : stage0;

    logic [1:0] sign2;
    assign sign2 = {2{stage1[31]}}; 

    assign left2 = {stage1[29:0], 2'b0};
    assign right2 = is_arith ? {sign2, stage1[31:2]} : {2'b0, stage1[31:2]};
    assign shift2 = is_right ? right2 : left2;
    assign stage2 = (i_shamt[1]) ? shift2 : stage1;

    logic [3:0] sign4;
    assign sign4 = {4{stage2[31]}};

    assign left4 = {stage2[27:0], 4'b0};
    assign right4 = is_arith ? {sign4, stage2[31:4]} : {4'b0, stage2[31:4]};
    assign shift4 = is_right ? right4 : left4;   
    assign stage4 = (i_shamt[2]) ? shift4 : stage2;

    logic [7:0] sign8;
    assign sign8 = {8{stage4[31]}};

    assign left8 = {stage4[23:0], 8'b0};
    assign right8 = is_arith ? {sign8, stage4[31:8]} : {8'b0, stage4[31:8]};
    assign shift8 = is_right ? right8 : left8;
    assign stage8 = (i_shamt[3]) ? shift8 : stage4;

    logic [15:0] sign16;
    assign sign16 = {16{stage8[31]}};

    assign left16 = {stage8[15:0], 16'b0};
    assign right16 = is_arith ? {sign16, stage8[31:16]} : {16'b0, stage8[31:16]};
    assign shift16 = is_right ? right16 : left16;
    assign stage16 = (i_shamt[4]) ? shift16 : stage8;   

    assign o_data = is_valid ? stage16 : 32'b0;

endmodule