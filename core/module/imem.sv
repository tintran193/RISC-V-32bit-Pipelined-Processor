module imem #(
    parameter logic [31:0] START_ADDR = 32'h8000_0000,
    parameter int unsigned ADDR_WIDTH = 19,
    parameter string    PROGRAMFILE = ""
) (
    input logic         i_clk,
    input logic [31:0]  i_addr,
    output logic [31:0] o_data
);
    
    localparam int unsigned MEM_SIZE = 1 << ADDR_WIDTH;
    localparam int unsigned MEM_DEPTH = MEM_SIZE >> 2;
    localparam int unsigned INDEX_WIDTH = ADDR_WIDTH - 2;

    logic [31:0] mem [0 : MEM_DEPTH-1];

//Chuyển đổi địa chỉ PC (byte addr) sang địa chỉ word (word addr) để truy cập bộ nhớ
    logic [INDEX_WIDTH-1:0] addr_index;
    assign addr_index = (i_addr - START_ADDR) >> 2;

    assign o_data = mem[addr_index];

endmodule

