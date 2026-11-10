module led (
    input logic i_clk,
    input logic i_rstn,
    input logic [11:0] i_addr,//offset address from bus
    input logic [31:0] i_wdata,
    input logic [3:0] i_bmsk,
    input logic i_wren,

    output logic [31:0] o_rdata,
    output logic [31:0] o_ledr,
    output logic [31:0] o_ledg,
    output logic [31:0] o_ledb   
);
    // Led registers
    logic [31:0] ledr_reg; //offset 0x000
    logic [31:0] ledg_reg; //offset 0x004
    logic [31:0] ledb_reg; //offset 0x008
  
    // Write to led registers
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            //Reset
            ledr_reg <= 32'b0;
            ledg_reg <= 32'b0;
            ledb_reg <= 32'b0;
        end else if (i_wren) begin
            // Write operation
            case (i_addr)
                12'h000: begin
                    if (i_bmsk[0]) ledr_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1]) ledr_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2]) ledr_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3]) ledr_reg[31:24] <= i_wdata[31:24];
                end
                12'h004: begin
                    if (i_bmsk[0]) ledg_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1]) ledg_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2]) ledg_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3]) ledg_reg[31:24] <= i_wdata[31:24];
                end
                12'h008: begin
                    if (i_bmsk[0]) ledb_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1]) ledb_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2]) ledb_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3]) ledb_reg[31:24] <= i_wdata[31:24];
                end
                default: begin
                    // Unmapped offset: ignore write
                end
            endcase
        end
    end

    // Read from led registers
    always_comb begin
        o_rdata = 32'b0; // Default: unmapped offset returns zero
        case (i_addr) 
            12'h000: o_rdata = ledr_reg;
            12'h004: o_rdata = ledg_reg;
            12'h008: o_rdata = ledb_reg;
            default: o_rdata = 32'b0; 
        endcase
    end

    // Assign led outputs
    assign o_ledr = ledr_reg;
    assign o_ledg = ledg_reg;
    assign o_ledb = ledb_reg;   

endmodule