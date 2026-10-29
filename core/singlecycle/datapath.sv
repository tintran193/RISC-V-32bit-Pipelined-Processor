module datapath (
    input logic i_clk, 
    input logic i_rstn,
    
//contronl signals
    input logic pc_sel,
    input logic immgen_sel,
    input logic br_un,
    input logic opa_sel,
    input logic opb_sel,
    input logic [3:0] alu_op,
    input logic rd_wren,
    input logic dmem_wren,

    output logic br_equal,
    output logic br_less,
    output logic [31:0] i_instr,

);

//Internal signals
    logic [31:0] pc, pc_next, pc_four;



//Khối PC 
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            pc <= 32'h8000_0000;
        end else begin
            pc <= pc_next;
        end
    end







endmodule