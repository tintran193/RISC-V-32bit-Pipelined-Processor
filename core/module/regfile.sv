module regfile (
    input logic i_clk,
    input logic i_rstn,
    input logic [4:0] i_rs1_addr,
    input logic [4:0] i_rs2_addr,
    input logic [4:0] i_rd_addr,
    input logic [31:0] i_rd_data,
    input logic i_rd_wren,

    output logic [31:0] o_rs1_data,
    output logic [31:0] o_rs2_data
);

// 32 registers of 32-bit width
    logic [31:0] regs [0:31];
// Write selection from decoder
    logic [31:0] wr_sel;
// Write enable (except for x0)
    logic wr_en;
    assign wr_en = i_rd_wren & (i_rd_addr != 5'b0);
// x0 is always zero
    assign regs[0] = 32'b0;
// Decoder 5 to 32
    decoder5to32 u_decoder (
        .i_en(wr_en),
        .i_addr(i_rd_addr),
        .o_decoded(wr_sel)
    );
// x1 to x31 registers
    genvar g;
    generate
        for (g = 1; g < 32; g = g + 1) begin : GEN_REGS
            register32 u_register32 (
                .i_clk(i_clk),
                .i_rstn(i_rstn),
                .i_wren(wr_sel[g]),
                .i_wdata(i_rd_data),
                .o_rdata(regs[g])
            );
        end
    endgenerate
// Read port 1
    mux32to1 u_mux32to1_rs1 (
        .i_data(regs),
        .i_sel(i_rs1_addr),
        .o_data(o_rs1_data)
    );
// Read port 2
    mux32to1 u_mux32to1_rs2 (
        .i_data(regs),
        .i_sel(i_rs2_addr),
        .o_data(o_rs2_data) 
    );

endmodule