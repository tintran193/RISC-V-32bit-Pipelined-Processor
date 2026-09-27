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

endmodule
    