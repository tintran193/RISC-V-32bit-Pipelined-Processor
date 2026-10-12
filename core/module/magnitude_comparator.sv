module magnitude_comparator (
    input logic [31:0] i_a;
    input logic [31:0] i_b;
    input logic i_unsigned; // 1 -> unsigned, 0 -> signed

    output logic o_eq,
    output logic o_lt,
    output logic o_gt
);
    // unsigned signals
    logic unsigned_eq;
    logic unsigned_lt;
    logic unsigned_gt;
    // signed signals
    logic same_sign;
    logic signed_lt;
    logic signed_gt;

    comparator32 u_comparator32 (
        .i_a (i_a),
        .i_b (i_b),
        .o_eq (unsigned_eq),
        .o_lt (unsigned_lt),
        .o_gt (unsigned_gt)
    );

    assign same_sign = ~(i_a[31] ^ i_b[31]);
    assign signed_lt = (i_a[31] & ~i_b[31]) | (same_sign & unsigned_lt);
    assign signed_gt = (~i_a[31] & i_b[31]) | (same_sign & unsigned_gt);
    
    // Output assignments
    assign o_eq = unsigned_eq;
    assign o_lt = i_unsigned ? unsigned_lt : signed_lt;
    assign o_gt = i_unsigned ? unsigned_gt : signed_gt;

endmodule