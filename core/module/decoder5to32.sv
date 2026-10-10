module decoder5to32 (
    input logic i_en,
    input logic [4:0] i_addr,
    output logic [31:0] o_decoded
);

    always_comb begin
        if (i_en) begin
            o_decoded = 32'b0;
            o_decoded[i_addr] = 1'b1;
        end else begin
            o_decoded = 32'b0;
        end
    end
endmodule