module mux2 (
    logic [31:0] i_in0,
    logic [31:0] i_in1,
    logic i_sel,
    logic [31:0] o_data
);

    assign o_data = i_sel ? i_in1 : i_in0;

endmodule