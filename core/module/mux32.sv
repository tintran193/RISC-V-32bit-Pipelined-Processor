module mux32 (
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
            mux2 u_mux2 (
                .i_in0(i_data[2*g]),
                .i_in1(i_data[2*g + 1]),
                .i_sel(i_sel[0]),
                .o_data(mux1[g])
            );
        end
    endgenerate
    // Mux 2: 16 to 8
    generate
        for (g = 0; g < 8; g = g + 1) begin : GEN_MUX2
            mux2 u_mux2 (
                .i_in0(mux1[2*g]),
                .i_in1(mux1[2*g + 1]),
                .i_sel(i_sel[1]),
                .o_data(mux2[g])
            );
        end
    endgenerate
    // Mux 3: 8 to 4
    generate
        for (g = 0; g < 4; g = g + 1) begin : GEN_MUX3
            mux2 u_mux2 (
                .i_in0(mux2[2*g]),
                .i_in1(mux2[2*g + 1]),
                .i_sel(i_sel[2]),
                .o_data(mux3[g])
            );
        end
    endgenerate
    // Mux 4: 4 to 2
    generate
        for (g = 0; g < 2; g = g + 1) begin : GEN_MUX4
            mux2 u_mux2 (
                .i_in0(mux3[2*g]),
                .i_in1(mux3[2*g + 1]),
                .i_sel(i_sel[3]),
                .o_data(mux4[g])
            );
        end
    endgenerate
    // Mux 5: 2 to 1
    mux2 u_mux2 (
        .i_in0(mux4[0]),
        .i_in1(mux4[1]),
        .i_sel(i_sel[4]),
        .o_data(o_data)
    );

endmodule
