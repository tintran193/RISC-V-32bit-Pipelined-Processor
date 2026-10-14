module alu (
    input  logic [31:0] i_op_a,
    input  logic [31:0] i_op_b,
    input  logic [3:0]  i_alu_op,
    output logic [31:0] o_alu_data
);
    `include "parameter.h"

// Adder/Subtractor
    logic [31:0] adder32_b;
    logic adder32_sub;
    logic [31:0] adder32_result;
    logic adder32_cout;

    always_comb begin
        case (i_alu_op)
            SUB: adder32_sub = 1'b1;
            default: adder32_sub = 1'b0;
        endcase
    end

    assign adder32_b = i_op_b ^ {32{adder32_sub}};

    adder32 u_adder32 (
        .i_a (i_op_a),
        .i_b (adder32_b),
        .i_sub (adder32_sub),
        .o_sum (adder32_result),
        .o_cout (adder32_cout)
    );

//Comparator
    logic i_unsigned;

    always_comb begin 
        case (i_alu_op)
            SLTU: i_unsigned = 1'b1;
            default: i_unsigned = 1'b0;
        endcase
    end

    logic o_eq;
    logic o_lt;
    logic o_gt;

    magnitude_comparator u_magnitude_comparator (
        .i_a (i_op_a),
        .i_b (i_op_b),
        .i_unsigned (i_unsigned),
        .o_eq (o_eq),
        .o_lt (o_lt),
        .o_gt (o_gt)
    );

    logic [31:0] slt_result;
    logic [31:0] sltu_result;

    assign slt_result = {31'b0, o_lt};
    assign sltu_result = {31'b0, o_lt};

// Logic Operations
    logic [31:0] and_result;
    logic [31:0] or_result;
    logic [31:0] xor_result;

    assign and_result = i_op_a & i_op_b;
    assign or_result  = i_op_a | i_op_b;
    assign xor_result = i_op_a ^ i_op_b;  

//Shifter 
    logic [1:0] i_mode;
    logic [31:0] shifter_result;

    always_comb begin
        case (i_alu_op)
            SRL: i_mode = 2'b00;
            SLL: i_mode = 2'b01;
            SRA: i_mode = 2'b10;
            default: i_mode = 2'b11;
        endcase
    end

    shifter32 u_shifter32 (
        .i_data (i_op_a),
        .i_shamt (i_op_b[4:0]),
        .i_mode (i_mode),
        .o_data (shifter_result)
    );

// Mux
    always_comb begin
        case (i_alu_op)
            ADD: o_alu_data = adder32_result;
            SUB: o_alu_data = adder32_result;
            SLT: o_alu_data = slt_result;
            SLTU: o_alu_data = sltu_result;
            XOR: o_alu_data = xor_result;
            OR:  o_alu_data = or_result;
            AND: o_alu_data = and_result;
            SLL: o_alu_data = shifter_result;
            SRL: o_alu_data = shifter_result;
            SRA: o_alu_data = shifter_result;
            default: o_alu_data = 32'b0;
        endcase
    end

endmodule
    