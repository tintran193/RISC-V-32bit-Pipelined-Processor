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

    logic        pc_sel;
    logic [2:0]  imm_sel;
    logic        rd_wren;
    logic        br_un;
    logic        opa_sel;
    logic        opb_sel;
    logic [3:0]  alu_op;
    logic        mem_wren;
    logic [1:0]  wb_sel;

    logic        br_equal;
    logic        br_less;
    logic        ctrl_db_valid;
    logic [31:0] instr;

// Datapath
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

        .i_instr_valid(ctrl_db_valid),
        .i_pc_sel(pc_sel),
        .i_imm_sel(imm_sel),    
        .i_br_un(br_un),
        .i_opa_sel(opa_sel),
        .i_opb_sel(opb_sel),
        .i_alu_op(alu_op),
        .i_rd_wren(rd_wren),
        .i_mem_wren(mem_wren),
        .i_wb_sel(wb_sel),
        .o_br_equal(br_equal),
        .o_br_less(br_less),
        .o_instr(instr)
    );

// Controller
    controller ctrl (
        .i_instr(instr),
        .i_br_equal(br_equal),
        .i_br_less(br_less),

        .o_pc_sel(pc_sel),
        .o_imm_sel(imm_sel),
        .o_rd_wren(rd_wren),
        .o_br_un(br_un),
        .o_opa_sel(opa_sel),
        .o_opb_sel(opb_sel),
        .o_alu_op(alu_op),
        .o_mem_wren(mem_wren),
        .o_wb_sel(wb_sel),
		.o_db_valid(ctrl_db_valid)
    );

    // The specification requires db_valid to remain low during reset.
    assign o_db_valid = i_rstn & ctrl_db_valid;

endmodule 