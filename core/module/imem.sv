module imem #(
    parameter logic [31:0] START_ADDR = 32'h8000_0000,
    parameter int unsigned ADDR_WIDTH = 19,
    parameter string PROGRAMFILE = ""
)(
    input logic i_clk,
    input logic [31:0] i_addr,
    output logic [31:0] o_data
);
    localparam int unsigned INDEX_WIDTH = ADDR_WIDTH - 2;
    localparam int unsigned MEM_SIZE = 1 << ADDR_WIDTH;
    localparam int unsigned MEM_DEPTH = MEM_SIZE >> 2;

    logic [31:0] mem [0:MEM_DEPTH-1];

    initial begin
	    if (PROGRAMFILE != "") begin
		    $readmemh(PROGRAMFILE, mem);
		end
	end

    logic [INDEX_WIDTH-1:0] addr_index;
	logic valid_addr;

	assign valid_addr = (i_addr >= START_ADDR) && (i_addr < START_ADDR + (2 ** ADDR_WIDTH));
 
	assign addr_index = (i_addr - START_ADDR) >> 2;

	always_comb begin
		if (valid_addr)
		 	o_data = mem[addr_index];
		else
			o_data = 32'b0;
	end

endmodule 
