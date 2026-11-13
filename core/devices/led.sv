
module led (
    input  logic        i_clk,
    input  logic        i_rstn,
    input  logic [11:0] i_addr, //offset address from bus
    input  logic [31:0] i_wdata,
    input  logic [3:0]  i_bmsk,
    input  logic        i_wren,

    output logic [31:0] o_rdata,
    output logic [31:0] o_ledr,
    output logic [31:0] o_ledg,
    output logic [31:0] o_ledb
);

    // Led registers
    logic [31:0] ledr_reg; //offset 0x000
    logic [31:0] ledg_reg; //offset 0x004
    logic [31:0] ledb_reg; //offset 0x008

    // Write operation
    always_ff @(posedge i_clk or negedge i_rstn) begin

        if (!i_rstn) begin
            // Reset all LED registers
            ledr_reg <= 32'b0;
            ledg_reg <= 32'b0;
            ledb_reg <= 32'b0;
        end else if (i_wren) begin
            case (i_addr[11:2])

                10'h000: begin // LEDR: offset 0x000

                    if (i_bmsk[0])
                        ledr_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1])
                        ledr_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2])
                        ledr_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3])
                        ledr_reg[31:24] <= i_wdata[31:24];

                end

                10'h001: begin // LEDG: offset 0x004
                    if (i_bmsk[0])
                        ledg_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1])
                        ledg_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2])
                        ledg_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3])
                        ledg_reg[31:24] <= i_wdata[31:24];
                end

                10'h002: begin // LEDB: offset 0x008
                    if (i_bmsk[0])
                        ledb_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1])
                        ledb_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2])
                        ledb_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3])
                        ledb_reg[31:24] <= i_wdata[31:24];
                end

                default: begin
                    // unmapped offsets: write ignored
                end

            endcase
        end
    end

    // Read operation
    always_comb begin
        // Default: unmapped address returns zero
        o_rdata = 32'b0;

        case (i_addr[11:2])
            10'h000: o_rdata = ledr_reg;
            10'h001: o_rdata = ledg_reg;
            10'h002: o_rdata = ledb_reg;
            // Reserved / unmapped offsets
            default: o_rdata = 32'b0;
        endcase
    end
    
    // Assign led outputs
    o_ledr = ledr_reg;
    o_ledg = ledg_reg;
    o_ledb = ledb_reg;  

endmodule
