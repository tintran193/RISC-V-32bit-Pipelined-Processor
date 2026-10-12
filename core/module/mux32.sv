module mux32 (
    input logic [31:0] i_a,
    input logic [31:0] i_b,
    input logic i_sel,
    output logic [31:0] o_y
);

    always_comb begin
        if (i_sel) begin
            o_y = i_b;
        end else begin
            o_y = i_a;
        end
    end
    
endmodule