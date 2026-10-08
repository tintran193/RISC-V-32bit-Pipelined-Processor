module dmem_sync #(
    parameter logic [31:0] STRT_ADDR = 32'h0000_0000,
    parameter integer ADDR_WIDTH = 10
) (
    input logic i_clk,
    input logic  [31:0] i_addr,
    input logic  [31:0] i_wdata,
    input logic  [3:0] i_bmsk,
    input logic  i_rden,
    input logic  i_wren,
    output logic [31:0] o_rdata 
);

endmodule