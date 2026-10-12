module shifter_stage #(
    parameter [4:0] SHIFT = 1'b0,
    parameter IS_RIGHT = 1'b0
) (
    input logic [31:0] i_data,
    input logic i_shift,
    input logic i_arith,
    
    output logic [31:0] o_data
);
    logic [31:0] shifted_data;
    
    genvar idx;

    generate 
        for (idx = 0; idx < 32; idx = idx + 1) begin : GEN_BIT
            if (IS_RIGHT == 0) begin : SHIFT_LEFT
                assign shifted_data[idx] = (idx >= SHIFT) ? i_data[idx - SHIFT] : 1'b0;
            end else begin : SHIFT_RIGHT
                assign shifted_data[idx] = (idx < 32 - SHIFT) ? i_data[idx + SHIFT] : (i_arith ? i_data[31] : 1'b0);
            end
        end
    endgenerate

    assign o_data = (i_shift) ? shifted_data : i_data;

endmodule