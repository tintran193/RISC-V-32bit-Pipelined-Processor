module register32 (
    input logic i_clk,
    input logic i_rstn,
    input logic i_wren,
    input logic [31:0] i_wdata,
    
    output logic [31:0] o_rdata
);

    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            o_rdata <= 32'b0;
        end else if (i_wren) begin
            o_rdata <= i_wdata;
        end
    end

endmodule