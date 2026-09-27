module comparator1 (
    input logic a,
    input logic b,
    output logic eq,
    output logic lt,
    output logic gt
);
    assign gt = a & ~b;
    assign lt = ~a & b;
    assign eq = ~(a ^ b);
    
endmodule