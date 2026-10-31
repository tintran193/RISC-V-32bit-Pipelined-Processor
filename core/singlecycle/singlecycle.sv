module singlecycle (
    input logic i_clk,
    input logic i_rstn, 
    input logic [31:0] i_imem_rdata,  // Instruction memory data input
    input logic [31:0] i_dmem_rdata,  // Data memory data input

    output logic [31:0] o_imem_addr, // Instruction memory address output
    output logic [31:0] o_dmem_addr, // Data memory address output
    output logic [31:0] o_dmem_wdata,
    output logic [3:0]  o_dmem_bmsk,
    output logic        o_dmem_wren,
	 output logic 		o_db_valid
  
);

//Tín hiệu điều khiển
    logic pc_sel, immgen_sel, br_un, opa_sel, opb_sel, rd_wren, dmem_wren;
    logic [3:0] alu_op;
    logic [1:0] wb_sel;
    logic br_equal, br_less;
    logic [31:0] instr;
	

    datapath dp (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_dmem_rdata(i_dmem_rdata),
        .i_imem_rdata(i_imem_rdata),   

        .o_imem_addr(o_imem_addr),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_bmsk(o_dmem_bmsk),
        .o_dmem_wren(o_dmem_wren),

        .pc_sel(pc_sel),
        .immgen_sel(immgen_sel),    
        .br_un(br_un),
        .opa_sel(opa_sel),
        .opb_sel(opb_sel),
        .alu_op(alu_op),
        .rd_wren(rd_wren),
        .dmem_wren(dmem_wren),
        .wb_sel(wb_sel),
        .br_equal(br_equal),
        .br_less(br_less),
        .o_instr(instr)
    );

    controller ctrl (
        .i_instr(instr),
        .i_br_equal(br_equal),
        .i_br_less(br_less),

        .o_pc_sel(pc_sel),
        .o_immgen_sel(immgen_sel),
        .o_rd_wren(rd_wren),
        .o_br_un(br_un),
        .o_opa_sel(opa_sel),
        .o_opb_sel(opb_sel),
        .o_alu_op(alu_op),
        .o_dmem_wren(dmem_wren),
        .o_wb_sel(wb_sel),
		  .o_db_valid(o_db_valid)
    );


endmodule 