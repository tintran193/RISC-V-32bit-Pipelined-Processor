module shifter (
    input logic [31:0] a,
    input logic [4:0] shamt,
    input logic [1:0] op,
    output logic [31:0] y
)
    localparam logic [1:0] SLL = 2'b00;
    localparam logic [1:0] SRL = 2'b01;
    localparam logic [1:0] SRA = 2'b10;

    always_comb begin
        case (op)
            SLL: y = a << shamt;
            SRL: y = a >> shamt;
            SRA: y = $signed(a) >>> shamt;
            default: y = 32'b0;
        endcase
    end
endmodule