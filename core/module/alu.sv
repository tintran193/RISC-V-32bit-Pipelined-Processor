module alu (
    input  logic [31:0] i_op_a,
    input  logic [31:0] i_op_b,
    input  logic [3:0]  i_alu_op,
    output logic [31:0] o_alu_data
);
    localparam logic [3:0] ADD = 4'b0000;
    localparam logic [3:0] SUB = 4'b0001;
    localparam logic [3:0] SLT = 4'b0010;   
    localparam logic [3:0] SLTU = 4'b0011;
    localparam logic [3:0] XOR = 4'b0100;
    localparam logic [3:0] OR  = 4'b0101;
    localparam logic [3:0] AND = 4'b0110;   
    localparam logic [3:0] SLL = 4'b0111;
    localparam logic [3:0] SRL = 4'b1000;
    localparam logic [3:0] SRA = 4'b1001;

// Adder/Subtractor
    logic [31:0] adde32_b;
    logic adder32_cin;
    logic [31:0] adder32_result;
    logic adder32_cout;

    always_comb begin
        case (i_alu_op)
            SUB: adder32_cin = 1'b1;
            default: adder32_cin = 1'b0;
        endcase
    end

    assign adder32_b = i_op_b ^ {32{adder32_cin}};

    adder32 u_adder32 (
        .i_a (i_op_a),
        .i_b (adder32_b),
        .i_cin (adder32_cin),
        .o_sum (adder32_result),
        .o_cout (adder32_cout)
    );

// Comparator
    // Unsigned 
    logic unsigned_lt;
    logic unsigned_eq;
    logic unsigned_gt;

    comparator32 u_comparator32 (
        .i_a (i_op_a),
        .i_b (i_op_b),
        .o_lt (unsigned_lt),
        .o_eq (unsigned_eq),
        .o_gt (unsigned_gt)
    );

    // Signed
    logic signed_lt;
    logic signed_eq; 

    assign signed_eq = ~(i_op_a[31] ^ i_op_b[31]);
    assign signed_lt = (i_op_a[31] & ~i_op_b[31]) | (signed_eq & unsigned_lt);

    logic [31:0] slt_result;
    logic [31:0] sltu_result;

    assign slt_result = {31'b0, signed_lt};
    assign sltu_result = {31'b0, unsigned_lt};

// Logic Operations
    logic [31:0] and_result;
    logic [31:0] or_result;
    logic [31:0] xor_result;

    assign and_result = i_op_a & i_op_b;
    assign or_result  = i_op_a | i_op_b;
    assign xor_result = i_op_a ^ i_op_b;  

// Shifter
    logic shift_right;
    logic shift_arith;
    logic [31:0] shifter_result;

    always_comb begin

        shight_right = 1'b0;
        shift_arith = 1'b0;

        case (i_alu_op)
            SLL: begin
                shift_right = 1'b0;
                shift_arith = 1'b0;
            end
            SRL: begin
                shift_right = 1'b1;
                shift_arith = 1'b0;
            end
            SRA: begin
                shift_right = 1'b1;
                shift_arith = 1'b1;
            end
            default: begin
                shift_right = 1'b0;
                shift_arith = 1'b0;
            end
        endcase
    end

    shifter32 u_shifter32 (
        .i_data (i_op_a),
        .i_shamt (i_op_b[4:0]),
        .i_right (shift_right),
        .i_arith (shift_arith),
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
    