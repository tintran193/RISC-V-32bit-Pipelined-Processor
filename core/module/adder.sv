module adder (
    input logic cin,
    input logic [31:0] operand_a,
    input logic [31:0] operand_b,
    output logic [31:0] sum,
    output logic cout
);
    assign {cout, sum} = operand_a + operand_b + cin;
endmodule
