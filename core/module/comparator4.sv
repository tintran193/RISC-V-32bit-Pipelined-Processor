module comparator4 (
    input logic [3:0] a,
    input logic [3:0] b,
    output logic eq,
    output logic lt,
    output logic gt
);
    logic eq3, eq2, eq1, eq0;
    assign eq3 = ~(a[3] ^ b[3]);
    assign eq2 = ~(a[2] ^ b[2]);
    assign eq1 = ~(a[1] ^ b[1]);
    assign eq0 = ~(a[0] ^ b[0]);
    
    assign gt = (a[3] & ~b[3]) | (eq3 & a[2] & ~b[2]) | (eq3 & eq2 & a[1] & ~b[1]) | (eq3 & eq2 & eq1 & a[0] & ~b[0]);
    assign eq = eq3 & eq2 & eq1 & eq0;
    assign lt = ~(gt | eq);

endmodule

