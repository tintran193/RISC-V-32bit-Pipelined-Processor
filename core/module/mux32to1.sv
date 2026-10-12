module mux32to1 (
    input logic [31:0] i_data [0:31],
    input logic [4:0] i_sel,

    output logic [31:0] o_data
);
    logic [31:0] mux1 [0:15];
    logic [31:0] mux2 [0:7];
    logic [31:0] mux3 [0:3];
    logic [31:0] mux4 [0:1];

    genvar g;

    // Mux 1: 32 to 16
    generate
        for (g = 0; g < 16; g = g + 1) begin : GEN_MUX1
            mux32 u_mux32 (
                .i_a(i_data[2*g]),
                .i_b(i_data[2*g + 1]),
                .i_sel(i_sel[0]),
                .o_y(mux1[g])
            );
        end
    endgenerate
    // Mux 2: 16 to 8
    generate
        for (g = 0; g < 8; g = g + 1) begin : GEN_MUX2
            mux32 u_mux32 (
                .i_a(mux1[2*g]),
                .i_b(mux1[2*g + 1]),
                .i_sel(i_sel[1]),
                .o_y(mux2[g])
            );
        end
    endgenerate
    // Mux 3: 8 to 4
    generate
        for (g = 0; g < 4; g = g + 1) begin : GEN_MUX3
            mux32 u_mux32 (
                .i_a(mux2[2*g]),
                .i_b(mux2[2*g + 1]),
                .i_sel(i_sel[2]),
                .o_y(mux3[g])
            );
        end
    endgenerate
    // Mux 4: 4 to 2
    generate
        for (g = 0; g < 2; g = g + 1) begin : GEN_MUX4
            mux32 u_mux32 (
                .i_a(mux3[2*g]),
                .i_b(mux3[2*g + 1]),
                .i_sel(i_sel[3]),
                .o_y(mux4[g])
            );
        end
    endgenerate
    // Mux 5: 2 to 1
    mux32 u_mux32 (
        .i_a(mux4[0]),
        .i_b(mux4[1]),
        .i_sel(i_sel[4]),
        .o_y(o_data)
    );

endmodule
