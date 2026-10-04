module regfile (
    input logic i_clk,
    input logic i_reset,
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

    integer i;
    initial regs[0] = 32'b0; // x0 is always zero

    always_ff @(posedge i_clk) begin
        if (!i_reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end 
        else begin
            if (i_rd_wren && (i_rd_addr != 5'b0)) begin
                regs[i_rd_addr] <= i_rd_data;
            end
        end
    end

    always_comb begin
        o_rs1_data = regs[i_rs1_addr];
        o_rs2_data = regs[i_rs2_addr];
    end

endmodule