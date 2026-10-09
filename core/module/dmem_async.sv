module dmem_async #(
    parameter logic [31:0] START_ADDR = 32'h0000_1000,
    parameter integer      ADDR_WIDTH = 5
) (
    input  logic        i_clk,
    input  logic [31:0] i_addr,
    input  logic [31:0] i_wdata,
    input  logic [3:0]  i_bmsk,
    input  logic        i_wren,

    output logic [31:0] o_rdata
);


    // Memory size
    // ADDR_WIDTH = number of byte-address bits
    // Number of bytes  = 2^ADDR_WIDTH
    // Number of words  = 2^(ADDR_WIDTH-2)

    localparam integer MEM_WORDS = 2 ** (ADDR_WIDTH - 2);

    // 32-bit word memory
    logic [31:0] mem [0:MEM_WORDS-1];

    logic [31:0] offset_addr;
    logic [31:0] word_index;
    logic        valid_addr;


    // Address calculation
    assign offset_addr = i_addr - START_ADDR;

    assign valid_addr =
        (i_addr >= START_ADDR) &&
        (i_addr < START_ADDR + (2 ** ADDR_WIDTH));


    // Word index
    // i_addr[1:0] -> byte postiotion within the word
    // i_addr[ADDR_WIDTH-1:2] -> word index

    generate
        if (ADDR_WIDTH == 2) begin : GEN_ONE_WORD
            assign word_index = 32'd0;
        end
        else begin : GEN_MULTI_WORD
            assign word_index = offset_addr[ADDR_WIDTH-1:2];
        end
    endgenerate

    // Synchronous write
    // Little-endian

    always_ff @(posedge i_clk) begin
        if (i_wren && valid_addr) begin
            if (i_bmsk[0]) begin
                mem[word_index][7:0] <= i_wdata[7:0];
            end 
            if (i_bmsk[1]) begin
                mem[word_index][15:8] <= i_wdata[15:8];
            end 
            if (i_bmsk[2]) begin
                mem[word_index][23:16] <= i_wdata[23:16];
            end 
            if (i_bmsk[3]) begin
                mem[word_index][31:24] <= i_wdata[31:24];
            end
        end
    end

    // Asynchronous read
    // Out-of-range read -> 0
    always_comb begin

        if (valid_addr) begin
            o_rdata = mem[word_index];
        end else begin
            o_rdata = 32'b0;
        end
    end

endmodule