module comparator32 (
    input logic [31:0] i_a,
    input logic [31:0] i_b,

    output logic o_eq,
    output logic o_lt,
    output logic o_gt
);
    logic [6:0] c_eq, c_lt, c_gt;

    comparator4_cascade cmp0 (
        .a (i_a[3:0]),
        .b (i_b[3:0]),
        .i_eq (1'b1),
        .i_lt (1'b0),
        .i_gt (1'b0),
        .o_eq (c_eq[0]),
        .o_lt (c_lt[0]),
        .o_gt (c_gt[0])
    );

    comparator4_cascade cmp1 (
        .a (i_a[7:4]),
        .b (i_b[7:4]),
        .i_eq (c_eq[0]),
        .i_lt (c_lt[0]),
        .i_gt (c_gt[0]),
        .o_eq (c_eq[1]),
        .o_lt (c_lt[1]),
        .o_gt (c_gt[1])
    );

    comparator4_cascade cmp2 (
        .a (i_a[11:8]),
        .b (i_b[11:8]),
        .i_eq (c_eq[1]),
        .i_lt (c_lt[1]),
        .i_gt (c_gt[1]),
        .o_eq (c_eq[2]),
        .o_lt (c_lt[2]),
        .o_gt (c_gt[2])
    );

    comparator4_cascade cmp3 (
        .a (i_a[15:12]),
        .b (i_b[15:12]),
        .i_eq (c_eq[2]),
        .i_lt (c_lt[2]),
        .i_gt (c_gt[2]),
        .o_eq (c_eq[3]),
        .o_lt (c_lt[3]),
        .o_gt (c_gt[3])
    );

    comparator4_cascade cmp4 (
        .a (i_a[19:16]),
        .b (i_b[19:16]),
        .i_eq (c_eq[3]),
        .i_lt (c_lt[3]),
        .i_gt (c_gt[3]),
        .o_eq (c_eq[4]),
        .o_lt (c_lt[4]),
        .o_gt (c_gt[4])
    );

    comparator4_cascade cmp5 (
        .a (i_a[23:20]),
        .b (i_b[23:20]),
        .i_eq (c_eq[4]),
        .i_lt (c_lt[4]),
        .i_gt (c_gt[4]),
        .o_eq (c_eq[5]),
        .o_lt (c_lt[5]),
        .o_gt (c_gt[5])
    );

    comparator4_cascade cmp6 (
        .a (i_a[27:24]),
        .b (i_b[27:24]),
        .i_eq (c_eq[5]),
        .i_lt (c_lt[5]),
        .i_gt (c_gt[5]),
        .o_eq (c_eq[6]),
        .o_lt (c_lt[6]),
        .o_gt (c_gt[6])
    );

    comparator4_cascade cmp7 (
        .a (i_a[31:28]),
        .b (i_b[31:28]),
        .i_eq (c_eq[6]),
        .i_lt (c_lt[6]),
        .i_gt (c_gt[6]),
        .o_eq (o_eq),
        .o_lt (o_lt),
        .o_gt (o_gt)
    );

endmodule