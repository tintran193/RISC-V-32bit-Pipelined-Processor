module comparator4_cascade (
    input logic [3:0] a,
    input logic [3:0] b,

    input logic i_eq,
    input logic i_lt,
    input logic i_gt,

    output logic o_eq,
    output logic o_lt,
    output logic o_gt
);
    logic local_eq3, local_eq2, local_eq1, local_eq0;
    assign local_eq3 = ~(a[3] ^ b[3]);
    assign local_eq2 = ~(a[2] ^ b[2]);
    assign local_eq1 = ~(a[1] ^ b[1]);
    assign local_eq0 = ~(a[0] ^ b[0]);

    assign local_eq = local_eq3 & local_eq2 & local_eq1 & local_eq0;
    assign local_gt = (a[3] & ~b[3]) | (local_eq3 & a[2] & ~b[2]) | (local_eq3 & local_eq2 & a[1] & ~b[1]) | (local_eq3 & local_eq2 & local_eq1 & a[0] & ~b[0]);
    assign local_lt = ~(local_gt | local_eq);

    assign o_eq = (local_eq & i_eq);
    assign o_gt = (local_gt | (local_eq & i_gt));
    assign o_lt = (local_lt | (local_eq & i_lt));

endmodule