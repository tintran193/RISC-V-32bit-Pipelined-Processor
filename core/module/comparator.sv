module comparator (
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    output logic eq,
    output logic lt,
    output logic gt
);
    assign eq = (operand_a == operand_b);
    assign lt = (operand_a < operand_b);
    assign gt = (operand_a > operand_b);
endmodule