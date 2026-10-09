module shifter32 (
    input logic [31:0] i_data,
    input logic [4:0] i_shamt,
    input logic [1:0] i_mode,

    output logic [31:0] o_data
); 
    // Mode decoding: 
    // 00: SRL
    // 01: SLL
    // 10: SRA
    // 11: Reserved

    logic is_right;
    logic is_arith;
    logic is_valid;

    assign is_right = ~i_mode[0];
    assign is_arith = i_mode[1] & ~i_mode[0];
    assign is_valid = ~(i_mode[1] & i_mode[0]);

    // Shift Left
    logic [31:0] left_stage1, left_stage2, left_stage4, left_stage8, left_stage16;

    shifter_stage #(.SHIFT(1), .IS_RIGHT(1'b0)) u_shift_left_stage1 (
        .i_data (i_data),
        .i_shift (i_shamt[0]),
        .i_arith (1'b0),
        .o_data (left_stage1)
    );

    shifter_stage #(.SHIFT(2), .IS_RIGHT(1'b0)) u_shift_left_stage2 (
        .i_data (left_stage1),
        .i_shift (i_shamt[1]),
        .i_arith (1'b0),
        .o_data (left_stage2)
    );

    shifter_stage #(.SHIFT(4), .IS_RIGHT(1'b0)) u_shift_left_stage4 (
        .i_data (left_stage2),
        .i_shift (i_shamt[2]),
        .i_arith (1'b0),
        .o_data (left_stage4)
    );

    shifter_stage #(.SHIFT(8), .IS_RIGHT(1'b0)) u_shift_left_stage8 (
        .i_data (left_stage4),
        .i_shift (i_shamt[3]),
        .i_arith (1'b0),
        .o_data (left_stage8)
    );

    shifter_stage #(.SHIFT(16), .IS_RIGHT(1'b0)) u_shift_left_stage16 (
        .i_data (left_stage8),
        .i_shift (i_shamt[4]),
        .i_arith (1'b0),
        .o_data (left_stage16)
    );

    // Shift Right
    logic [31:0] right_stage1, right_stage2, right_stage4, right_stage8, right_stage16;

    shifter_stage #(.SHIFT(1), .IS_RIGHT(1'b1)) u_shift_right_stage1 (
        .i_data (i_data),
        .i_shift (i_shamt[0]),
        .i_arith (is_arith),
        .o_data (right_stage1)
    );

    shifter_stage #(.SHIFT(2), .IS_RIGHT(1'b1)) u_shift_right_stage2 (
        .i_data (right_stage1),
        .i_shift (i_shamt[1]),
        .i_arith (is_arith),
        .o_data (right_stage2)
    );

    shifter_stage #(.SHIFT(4), .IS_RIGHT(1'b1)) u_shift_right_stage4 (
        .i_data (right_stage2),
        .i_shift (i_shamt[2]),
        .i_arith (is_arith),
        .o_data (right_stage4)
    );

    shifter_stage #(.SHIFT(8), .IS_RIGHT(1'b1)) u_shift_right_stage8 (
        .i_data (right_stage4),
        .i_shift (i_shamt[3]),
        .i_arith (is_arith),
        .o_data (right_stage8)
    );

    shifter_stage #(.SHIFT(16), .IS_RIGHT(1'b1)) u_shift_right_stage16 (
        .i_data (right_stage8),
        .i_shift (i_shamt[4]),
        .i_arith (is_arith),
        .o_data (right_stage16)
    );

    // Final Mux 32 bits
    always_comb begin
        if (is_valid) begin
            if (is_right) begin
                o_data = right_stage16;
            end else begin
                o_data = left_stage16;
            end 
        end else begin
            o_data = 32'b0; // Reserved mode
        end
    end


endmodule
