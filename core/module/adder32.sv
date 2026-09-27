module adder (
    input  logic [31:0] i_a,
    input  logic [31:0] i_b,
    input  logic        i_cin,
    output logic [31:0] o_sum,
    output logic        o_cout
);

    logic [32:0] c;
    genvar g;

    assign c[0] = i_cin;

    generate
        for (g = 0; g < 32; g = g + 1) begin : GEN_FA
            full_adder fa (
                .i_a (i_a[g]),
                .i_b (i_b[g]),
                .i_cin (c[g]),
                .o_sum (o_sum[g]),
                .o_cout (c[g+1])
            );
        end
    endgenerate

    assign o_cout = c[32];

endmodule