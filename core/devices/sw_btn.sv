module sw_btn (
    input logic i_clk,
    input logic i_rstn,
    input logic [11:0] i_addr,//offset address from bus
    input logic [31:0] i_wdata,
    input logic [3:0] i_bmsk,
    input logic i_wren,
    input logic [31:0] i_sw,
    input logic [31:0] i_btn,

    output logic [31:0] o_rdata,
    output logic [31:0] o_sw_data,
    output logic [31:0] o_btn_data
);
    //Switches 
    logic [31:0] sw_reg; //offset 0x000: addr 0x4000_2000
    logic [31:0] btn_reg; //offset 0x000: addr 0x4000_3000

endmodule