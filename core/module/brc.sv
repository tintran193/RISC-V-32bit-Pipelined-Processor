module brc (
    input logic [31:0] i_rs1_data,
    input logic [31:0] i_rs2_data,
    input logic is_br_un,

    output logic o_br_less,
    output logic o_br_equal
);

    logic unsigned_gt, unsigned_eq, unsigned_lt;
    logic signed_eq, signed_lt;

    comparator32 u_comparator32 (
        .i_a (i_rs1_data),
        .i_b (i_rs2_data),
        .o_lt (unsigned_lt),
        .o_eq (unsigned_eq),
        .o_gt (unsigned_gt)
    );

    assign sign_eq = ~(i_rs1_data[31] ^ i_rs2_data[31]);
    assign signed_lt = (i_rs1_data[31] & ~i_rs2_data[31]) | (sign_eq & unsigned_lt);

    assign o_br_less = is_br_un ? signed_lt : unsigned_lt;
    assign o_br_equal = unsigned_eq;

endmodule