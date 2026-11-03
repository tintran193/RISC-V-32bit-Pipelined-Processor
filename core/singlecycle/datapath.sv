module datapath (
    input logic i_clk, 
    input logic i_rstn,
    input logic [31:0] i_dmem_rdata,
    input logic [31:0] i_imem_rdata,

    output logic [31:0] o_imem_addr, // Instruction memory address output
    output logic [31:0] o_dmem_addr, 
    output logic [31:0] o_dmem_wdata,
    output logic [3:0]  o_dmem_bmsk,
    output logic        o_dmem_wren,

//control signals
    input logic i_instr_valid,
    input logic i_pc_sel,
    input logic [2:0] i_imm_sel,
    input logic i_rd_wren,
    input logic i_br_un,
    input logic i_opa_sel,
    input logic i_opb_sel,
    input logic [3:0] i_alu_op,
    input logic i_mem_wren,
    input logic [1:0] i_wb_sel,

    output logic [31:0] o_instr,
    output logic o_br_equal,
    output logic o_br_less
);

//PC signals
	logic [31:0] pc, pc_next, pc_four, instr;
	logic pc_cout;
//RegFile signals
	logic [31:0] rs1_data, rs2_data; 
//ALU signals    
    logic [31:0] operand_a, operand_b, alu_data;
//ImmGen signals
    logic [31:0] imm;
//LSU and WB signals
	logic [31:0] ld_data, wb_data; 

// PC block 
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            pc <= 32'h8000_0000;
        end else if (i_instr_valid) begin
            pc <= pc_next;
        end
    end

   mux2 pc_mux (
        .i_in0(pc_four),
        .i_in1(alu_data),
        .i_sel(i_pc_sel),
        .o_data(pc_next)
    );

   adder32 pc_adder (
        .i_a(pc),
        .i_b(32'd4),
        .i_sub(1'b0),
        .o_sum(pc_four),
        .o_cout(pc_cout)
    );

//IMEM block 
    assign o_imem_addr = pc;
	 
	always_comb begin
		if(!i_rstn) begin
			instr = 32'b0;
		end else begin
			instr = i_imem_rdata;
		end
	end

    assign o_instr = instr;

//Regfile block
    regfile u_regfile (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_rs1_addr(instr[19:15]),
        .i_rs2_addr(instr[24:20]),
        .i_rd_addr(instr[11:7]),
        .i_rd_data(wb_data),
        .i_rd_wren(i_rd_wren),
        .o_rs1_data(rs1_data),
        .o_rs2_data(rs2_data)
    );

//BRC block
    brc u_brc (
        .i_rs1_data(rs1_data),
        .i_rs2_data(rs2_data),
        .i_br_unsigned(i_br_un),
        .o_br_equal(o_br_equal),
        .o_br_less(o_br_less)
    );

//ImmGen block
    immgen u_immgen (
        .i_instr(instr),
        .i_imm_sel(i_imm_sel),
        .o_imm(imm)
    );


//ALU block
    mux2 opa_mux (
        .i_in0(rs1_data),
        .i_in1(pc),
        .i_sel(i_opa_sel),
        .o_data(operand_a)
    );

    mux2 opb_mux (
        .i_in0(rs2_data),
        .i_in1(imm),
        .i_sel(i_opb_sel),
        .o_data(operand_b)
    );

    alu u_alu (
        .i_op_a (operand_a),
        .i_op_b (operand_b),
        .i_alu_op (i_alu_op),
        .o_alu_data (alu_data)
    );  

//LSU
    lsu u_lsu (
        .i_funct3(instr[14:12]),
        .i_rdata(i_dmem_rdata),
        .i_addr(alu_data),
        .i_wdata(rs2_data),
        .i_wren(i_mem_wren),
        .o_ld_data(ld_data),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_bmsk(o_dmem_bmsk),
        .o_dmem_wren(o_dmem_wren)
    );  

    mux4 wb_mux (
        .i_in0(ld_data),
        .i_in1(alu_data),
        .i_in2(pc_four),
        .i_in3(32'b0),
        .i_sel(i_wb_sel),
        .o_data(wb_data)
    );

endmodule