module datapath (
    input logic i_clk, 
    input logic i_rstn,
    input logic [31:0] i_dmem_rdata,

    output logic [31:0] o_dmem_addr,
    output logic [31:0] o_dmem_wdata,
    output logic [3:0]  o_dmem_bmsk,
    output logic        o_dmem_wren,

//contronl signals
    input logic pc_sel,
    input logic immgen_sel,
    input logic br_un,
    input logic opa_sel,
    input logic opb_sel,
    input logic [3:0] alu_op,
    input logic rd_wren,
    input logic dmem_wren,
    input logic [1:0] wb_sel,

    output logic br_equal,
    output logic br_less,
    output logic [31:0] i_instr
);

//Khối PC
	logic [31:0] pc, pc_next, pc_four;
	
	//Khối ALU
	logic [31:0] rs1_data, rs2_data, operand_a, operand_b, alu_data, imm;
	
	//Khối LSU và WB
	logic [31:0] ld_data, wb_data; 

//Khối PC 
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if(!i_rstn) begin
            pc <= 32'h8000_0000;
        end else begin
            pc <= pc_next;
        end
    end

   mux2 pc_mux (
        .i_in0(pc_four),
        .i_in1(alu_data),
        .i_sel(pc_sel),
        .o_data(pc_next)
    );

    adder pc_adder (
        .i_in0(pc),
        .i_in1(32'd4),
        .o_data(pc_four)
    );

//Khối IMEM 
    imem #(
        .START_ADDR(32'h8000_0000),
        .ADDR_WIDTH(19),
        .PROGRAMFILE("program.hex") //để tạm
    ) imem_inst (
        .i_clk(i_clk),
        .i_addr(pc),
        .o_data(i_instr)
    );

//Khối Regfile
    regfile regfile_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_rs1_addr(i_instr[19:15]),
        .i_rs2_addr(i_instr[24:20]),
        .i_rd_addr(i_instr[11:7]),
        .i_rd_data(wb_data),
        .i_rd_wren(rd_wren),
        .o_rs1_data(rs1_data),
        .o_rs2_data(rs2_data)
    );

//Khối BRC
    brc brc (
        .i_rs1_data(rs1_data),
        .i_rs2_data(rs2_data),
        .i_br_unsigned(br_un),
        .o_br_equal(br_equal),
        .o_br_less(br_less)
    );

//Khối ImmGen
    ImmGen immgen (
        .i_instr(i_instr),
        .i_imm_sel(immgen_sel),
        .o_imm(imm)
    );


//Cụm ALU
    mux2 opa_mux (
        .i_in0(rs1_data),
        .i_in1(pc),
        .i_sel(opa_sel),
        .o_data(operand_a)
    );

    mux2 opb_mux (
        .i_in0(rs2_data),
        .i_in1(imm),
        .i_sel(opb_sel),
        .o_data(operand_b)
    );

    alu alu1 (
        .i_op_a (operand_a),
        .i_op_b (operand_b),
        .i_alu_op (alu_op),
        .o_alu_data (alu_data)
    );  

//Khối LSU
    lsu lsu1 (
        .i_clk(i_clk),
        .i_funct3(i_instr[14:12]),
        .i_dmem_rdata(i_dmem_rdata),
        .i_dmem_addr(alu_data),
        .i_dmem_wdata(rs2_data),
        .i_dmem_wren(dmem_wren),
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
        .i_in3(imm),
        .i_sel(wb_sel),
        .o_data(wb_data)
    );

endmodule