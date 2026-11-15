module gpio_ctrl (
    input  logic i_clk,
    input  logic i_rstn,
    input  logic [11:0] i_addr,
    input  logic [31:0] i_wdata,
    input  logic [3:0]  i_bmsk,
    input  logic        i_wren,

    input  logic [31:0] i_gpio_in,

    output logic [31:0] o_gpio_out,
    output logic [31:0] o_gpio_dir,
    output logic [31:0] o_rdata
);

    logic [31:0] gpio_out_reg; //offset 0x000
    logic [31:0] gpio_dir_reg; //offset 0x004

    // Its value is obtained from GPIO_OUT or external GPIO inputs.
    logic [31:0] gpio_in_value; //offset 0x008

    // Write operation
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            // Reset GPIO output value
            gpio_out_reg <= 32'b0;
            // Reset all GPIO pins to input mode
            gpio_dir_reg <= 32'b0;
        end else if (i_wren) begin
            case (i_addr[11:2])
            
                10'h000: begin // GPIO_OUT: offset 0x000
                    if (i_bmsk[0])
                        gpio_out_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1])
                        gpio_out_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2])
                        gpio_out_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3])
                        gpio_out_reg[31:24] <= i_wdata[31:24];
                end

                10'h001: begin // GPIO_DIR: offset 0x004
                    if (i_bmsk[0])
                        gpio_dir_reg[7:0] <= i_wdata[7:0];
                    if (i_bmsk[1])
                        gpio_dir_reg[15:8] <= i_wdata[15:8];
                    if (i_bmsk[2])
                        gpio_dir_reg[23:16] <= i_wdata[23:16];
                    if (i_bmsk[3])
                        gpio_dir_reg[31:24] <= i_wdata[31:24];
                end

                10'h002: begin // GPIO_IN: offset 0x008
                    // Write ignored
                end

                default: begin
                    // Unmapped offsets: write ignored
                end

            endcase
        end
    end

    // Determine GPIO input value  
    assign gpio_in_value = (gpio_out_reg & gpio_dir_reg) | (i_gpio_in & ~gpio_dir_reg);

    // Read operation
    always_comb begin
        // Default: unmapped address returns zero
        o_rdata = 32'b0;

        case (i_addr[11:2])
            10'h000: o_rdata = gpio_out_reg;
            10'h001: o_rdata = gpio_dir_reg;
            10'h002: o_rdata = gpio_in_value;
            // Reserved/Unmapped offsets
            default:
                o_rdata = 32'b0;
        endcase
    end

    // Assign gpio output signals    
    assign o_gpio_out = gpio_out_reg;
    assign o_gpio_dir = gpio_dir_reg;

endmodule
