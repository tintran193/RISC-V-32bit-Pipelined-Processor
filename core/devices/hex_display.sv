module hex_display (
    input logic i_clk,
    input logic i_rstn,
    input logic [11:0] i_addr,//offset address from bus
    input logic [31:0] i_wdata,
    input logic i_wren,
    input logic [3:0] i_bmsk,

    output logic [31:0] o_rdata,
    output logic [6:0] o_hex0,
    output logic [6:0] o_hex1,
    output logic [6:0] o_hex2,
    output logic [6:0] o_hex3,
    output logic [6:0] o_hex4,
    output logic [6:0] o_hex5,
    output logic [6:0] o_hex6,
    output logic [6:0] o_hex7
);

    //Hex display registers
    logic [6:0] hex0_reg; //offset 0x000
    logic [6:0] hex1_reg; //offset 0x004
    logic [6:0] hex2_reg; //offset 0x008
    logic [6:0] hex3_reg; //offset 0x00C
    logic [6:0] hex4_reg; //offset 0x010
    logic [6:0] hex5_reg; //offset 0x014
    logic [6:0] hex6_reg; //offset 0x018
    logic [6:0] hex7_reg; //offset 0x01C

    // Write to hex display registers
    always_ff @(posedge i_clk or negedge i_rstn) begin
        // Reset all hex display registers
        if(!i_rstn) begin
            hex0_reg <= 7'b0;
            hex1_reg <= 7'b0;
            hex2_reg <= 7'b0;
            hex3_reg <= 7'b0;
            hex4_reg <= 7'b0;
            hex5_reg <= 7'b0;
            hex6_reg <= 7'b0;
            hex7_reg <= 7'b0;
        end else if (i_wren & i_bmsk[0]) begin
                case (i_addr[11:2])
                    10'h000: hex0_reg <= i_wdata [6:0];
                    10'h001: hex1_reg <= i_wdata [6:0];
                    10'h002: hex2_reg <= i_wdata [6:0];
                    10'h003: hex3_reg <= i_wdata [6:0];
                    10'h004: hex4_reg <= i_wdata [6:0];
                    10'h005: hex5_reg <= i_wdata [6:0];
                    10'h006: hex6_reg <= i_wdata [6:0];
                    10'h007: hex7_reg <= i_wdata [6:0];
                    default: begin
                        // Unmapped offset: ignore write
                    end
                endcase
         end
    end 

    // Read from hex display registers
    always_comb begin
        o_rdata = 32'b0; // Default: unmapped offset returns zero
        case (i_addr[11:2]) 
            10'h000: o_rdata = {25'b0, hex0_reg};
            10'h001: o_rdata = {25'b0, hex1_reg};
            10'h002: o_rdata = {25'b0, hex2_reg};
            10'h003: o_rdata = {25'b0, hex3_reg};
            10'h004: o_rdata = {25'b0, hex4_reg};
            10'h005: o_rdata = {25'b0, hex5_reg};
            10'h006: o_rdata = {25'b0, hex6_reg};
            10'h007: o_rdata = {25'b0, hex7_reg};
            default: o_rdata = 32'b0; 
        endcase
    end 

    // Assign hex display outputs
    assign o_hex0 = ~hex0_reg;
    assign o_hex1 = ~hex1_reg;
    assign o_hex2 = ~hex2_reg;
    assign o_hex3 = ~hex3_reg;
    assign o_hex4 = ~hex4_reg;
    assign o_hex5 = ~hex5_reg;
    assign o_hex6 = ~hex6_reg;
    assign o_hex7 = ~hex7_reg;

endmodule