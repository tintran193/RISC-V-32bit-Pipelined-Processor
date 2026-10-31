module mux4 (
    logic [31:0] i_in0,
    logic [31:0] i_in1,
    logic [31:0] i_in2,
    logic [31:0] i_in3,
    logic [1:0] i_sel,
    logic [31:0] o_data
);

    always_comb begin
        case (i_sel)
            2'b00: o_data = i_in0;
            2'b01: o_data = i_in1;
            2'b10: o_data = i_in2;
            2'b11: o_data = i_in3;
            default: o_data = 32'h00000000;
        endcase
    end

endmodule