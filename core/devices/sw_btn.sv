
module sw_btn (
    input  logic [11:0] i_addr,
    input  logic [17:0] i_sw,
    input  logic [3:0] i_btn,

    output logic [31:0] o_sw_rdata,
    output logic [31:0] o_btn_rdata
);

    // Switch and button registers
    logic [31:0] sw_reg;
    logic [31:0] btn_reg;

    logic [3:0] btn_value;

    assign btn_value = ~i_btn[3:0];

    // Read operation
    always_comb begin
        // Default:
        // Unmapped register address returns zero.
        sw_reg  = 32'b0;
        btn_reg = 32'b0;

        // Both devices have register offset 0x000.
        // Their full addresses are distinguished by Simple Bus.
        case (i_addr[11:2])

            10'h000: begin
                sw_reg = {14'b0, i_sw};
                btn_reg = {28'b0, btn_value};
            end
            // Reserved offsets -> Read as 0
            default: begin
                sw_reg  = 32'b0;
                btn_reg = 32'b0;
            end

        endcase
    end

    // Assign read data outputs
    assign o_sw_rdata  = sw_reg;
    assign o_btn_rdata = btn_reg;

endmodule
