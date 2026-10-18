module brc (
    input logic [31:0] i_rs1_data,
    input logic [31:0] i_rs2_data,
    input logic i_br_unsigned,

    output logic o_br_equal,
    output logic o_br_less
);

    logic br_gt;

    magnitude_comparator u_magnitude_comparator (
        .i_a (i_rs1_data),
        .i_b (i_rs2_data),
        .i_unsigned (i_br_unsigned),
        .o_eq (o_br_equal),
        .o_lt (o_br_less),
        .o_gt (br_gt)
    );

endmodule