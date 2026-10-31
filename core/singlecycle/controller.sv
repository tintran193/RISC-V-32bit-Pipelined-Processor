module controller (
	input logic [31:0] i_instr, 
	input logic i_br_equal, 
	input logic i_br_less,
	
	output logic o_pc_sel,
	output logic [2:0] o_immgen_sel, 
	output logic o_rd_wren,
	output logic o_br_un,
	output logic o_opa_sel, 
	output logic o_opb_sel, 
	output logic [3:0] o_alu_op, 
	output logic o_dmem_wren, 
	output logic [1:0] o_wb_sel,
	output logic o_db_valid
	
);



//Tín hiệu nội 
	logic R_type, S_type, B_type, I_type, L_type, JALR_type, JAL_type, AUIPC_type, LUI_type;
	logic RV32; 

//Giải mã opcode 
	assign RV32   		=  i_instr[0] &  i_instr[1];
	assign R_type 		= ~i_instr[6] &  i_instr[5] &  i_instr[4] & ~i_instr[3] & ~i_instr[2] & RV32;
	assign S_type 		= ~i_instr[6] &  i_instr[5] & ~i_instr[4] & ~i_instr[3] & ~i_instr[2] & RV32;
	assign B_type 		=  i_instr[6] &  i_instr[5] & ~i_instr[4] & ~i_instr[3] & ~i_instr[2] & RV32;
	assign I_type 		= ~i_instr[6] & ~i_instr[5] &  i_instr[4] & ~i_instr[3] & ~i_instr[2] & RV32;
	assign L_type 		= ~i_instr[6] & ~i_instr[5] & ~i_instr[4] & ~i_instr[3] & ~i_instr[2] & RV32;
	assign JALR_type  =  i_instr[6] &  i_instr[5] & ~i_instr[4] & ~i_instr[3] &  i_instr[2] & RV32;
	assign JAL_type   =  i_instr[6] &  i_instr[5] & ~i_instr[4] &  i_instr[3] &  i_instr[2] & RV32;
	assign AUIPC_type = ~i_instr[6] & ~i_instr[5] &  i_instr[4] & ~i_instr[3] &  i_instr[2] & RV32;
	assign LUI_type 	= ~i_instr[6] &  i_instr[5] &  i_instr[4] & ~i_instr[3] &  i_instr[2] & RV32;
	
//Giải mã lệnh 
	logic add, sub, sll, slt, sltu, xor_r, srl, sra, or_r, and_r ; 
	logic sb, sh, sw; 
	logic beq, bne, blt, bge, bltu, bgeu;
	logic slli, srli, srai; 
	logic lb, lh, lw, lbu, lhu;
	logic addi, slti, sltiu, xori, ori, andi; 
	logic jalr, jal;
	logic lui, auipc; 
	
//R_type	
	assign add 		= ~i_instr[30] & ~i_instr[14] & ~i_instr[13] & ~i_instr[12] & R_type; 
	assign sub 		=  i_instr[30] & ~i_instr[14] & ~i_instr[13] & ~i_instr[12] & R_type; 
	assign sll 		= ~i_instr[30] & ~i_instr[14] & ~i_instr[13] &  i_instr[12] & R_type; 
	assign slt 		= ~i_instr[30] & ~i_instr[14] &  i_instr[13] & ~i_instr[12] & R_type; 
	assign sltu		= ~i_instr[30] & ~i_instr[14] &  i_instr[13] &  i_instr[12] & R_type; 
	assign xor_r 	= ~i_instr[30] &  i_instr[14] & ~i_instr[13] & ~i_instr[12] & R_type; 
	assign srl	   = ~i_instr[30] &  i_instr[14] & ~i_instr[13] &  i_instr[12] & R_type; 
	assign sra 		=  i_instr[30] &  i_instr[14] & ~i_instr[13] &  i_instr[12] & R_type; 
	assign or_r	   = ~i_instr[30] &  i_instr[14] &  i_instr[13] & ~i_instr[12] & R_type; 
	assign and_r   = ~i_instr[30] &  i_instr[14] &  i_instr[13] &  i_instr[12] & R_type; 
	
//S_type 
	assign sb = ~i_instr[14] & ~i_instr[13] & ~i_instr[12] & S_type; 
	assign sh = ~i_instr[14] & ~i_instr[13] &  i_instr[12] & S_type; 
	assign sw = ~i_instr[14] &  i_instr[13] & ~i_instr[12] & S_type; 
	
//B_type 
	assign beq 	= ~i_instr[14] & ~i_instr[13] & ~i_instr[12] & B_type;
	assign bne	= ~i_instr[14] & ~i_instr[13] &  i_instr[12] & B_type; 
	assign blt	=  i_instr[14] & ~i_instr[13] & ~i_instr[12] & B_type; 
	assign bge 	=  i_instr[14] & ~i_instr[13] &  i_instr[12] & B_type; 
	assign bltu =  i_instr[14] &  i_instr[13] & ~i_instr[12] & B_type; 
	assign bgeu =  i_instr[14] &  i_instr[13] &  i_instr[12] & B_type; 
	
//I_type shift 
	assign slli = ~i_instr[30] & ~i_instr[14] & ~i_instr[13] &  i_instr[12] & I_type; 
	assign srli = ~i_instr[30] &  i_instr[14] & ~i_instr[13] &  i_instr[12] & I_type; 
	assign srai =  i_instr[30] &  i_instr[14] & ~i_instr[13] &  i_instr[12] & I_type; 
	
//L_type  
	assign lb  = ~i_instr[14] & ~i_instr[13] & ~i_instr[12] & L_type; 
	assign lh  = ~i_instr[14] & ~i_instr[13] &  i_instr[12] & L_type; 
	assign lw  = ~i_instr[14] &  i_instr[13] & ~i_instr[12] & L_type; 
	assign lbu =  i_instr[14] & ~i_instr[13] & ~i_instr[12] & L_type; 
	assign lhu =  i_instr[14] & ~i_instr[13] &  i_instr[12] & L_type; 
	
//I_type 
	assign addi  = ~i_instr[14] & ~i_instr[13] & ~i_instr[12] & I_type; 
	assign slti  = ~i_instr[14] &  i_instr[13] & ~i_instr[12] & I_type; 
	assign sltiu = ~i_instr[14] &  i_instr[13] &  i_instr[12] & I_type; 
	assign xori  =  i_instr[14] & ~i_instr[13] & ~i_instr[12] & I_type; 
	assign ori   =  i_instr[14] &  i_instr[13] & ~i_instr[12] & I_type; 
	assign andi  =  i_instr[14] &  i_instr[13] &  i_instr[12] & I_type; 
	
//J_type
	assign jalr = ~i_instr[14] & ~i_instr[13] & ~i_instr[12] & JALR_type; 
	assign jal  = JAL_type; 
	
//U_type
	assign lui = LUI_type;
	assign auipc = AUIPC_type; 
 	
	
	
//Control word 
	logic [15:0] control_word;
	
	assign {o_pc_sel, o_immgen_sel, o_br_un, o_opa_sel, o_opb_sel, o_alu_op, o_rd_wren, o_dmem_wren, o_wb_sel, o_db_valid} = control_word;
	
	
	always_comb begin
		control_word = 16'd0;

//R_type 	
		if (add) begin
			control_word = 16'b0_000_0_0_0_0000_1_0_01_1;
		end else if (sub) begin
			control_word = 16'b0_000_0_0_0_0001_1_0_01_1; 
		end else if (sll) begin
			control_word = 16'b0_000_0_0_0_0111_1_0_01_1; 
		end else if (slt) begin
			control_word = 16'b0_000_0_0_0_0010_1_0_01_1; 
		end else if (sltu) begin
			control_word = 16'b0_000_0_0_0_0011_1_0_01_1;
		end else if (xor_r) begin
			control_word = 16'b0_000_0_0_0_0100_1_0_01_1;
		end else if (srl) begin
			control_word = 16'b0_000_0_0_0_1000_1_0_01_1;
		end else if (sra) begin
			control_word = 16'b0_000_0_0_0_1001_1_0_01_1;
		end else if (or_r) begin
			control_word = 16'b0_000_0_0_0_0101_1_0_01_1;
		end else if (and_r) begin
			control_word = 16'b0_000_0_0_0_0110_1_0_01_1;
		end
//Store
		end else if (sb || sh || sw) begin
			control_word = 16'b0_001_0_0_1_0000_0_1_xx_1;
		
		
//I_type 
		end else if (slli) begin
			control_word = 16'b0_000_0_0_1_0111_1_0_01_1;
		end else if (srli) begin
			control_word = 16'b0_000_0_0_1_1000_1_0_01_1;
		end else if (srai) begin
			control_word = 16'b0_000_0_0_1_1001_1_0_01_1;
		end else if (addi) begin
			control_word = 16'b0_000_0_0_1_0000_1_0_01_1;
		end else if (slti) begin
			control_word = 16'b0_000_0_0_1_0010_1_0_01_1;
		end else if (sltiu) begin
			control_word = 16'b0_000_0_0_1_0011_1_0_01_1;
		end else if (xori) begin
			control_word = 16'b0_000_0_0_1_0100_1_0_01_1;
		end else if (ori) begin
		   control_word = 16'b0_000_0_0_1_0101_1_0_01_1;
		end else if (andi) begin
		   control_word = 16'b0_000_0_0_1_0110_1_0_01_1;
	 
//L_type	 
		end else if (lb || lh || lw || lbu || lhu) begin
		   control_word = 16'b0_000_0_0_1_0000_1_0_00_1;
		
//JALR_type 
		end else if (jalr) begin
			control_word = 16'b1_000_0_0_1_0000_1_0_10_1;
		
//JAL_type		
		end else if (jal) begin
			control_word = 16'b1_011_0_1_1_0000_1_0_10_1;
		
//U_type 
		end else if (lui) begin
			control_word = 16'b0_100_0_x_1_0000_1_0_11_1;
		end else if (auipc) begin
			control_word = 16'b0_100_0_1_1_0000_1_0_01_1;
		
//B_type		
		end else if (beq) begin
			if(i_br_equal) begin
				control_word = 16'b1_010_0_1_1_0000_0_0_xx_1;
			end else begin
				control_word = 16'b0_010_0_1_1_0000_0_0_xx_1;
			end
		end else if (bne) begin
			if (!i_br_equal) begin
				control_word = 16'b1_010_0_1_1_0000_0_0_xx_1;
			end else begin
				control_word = 16'b0_010_0_1_1_0000_0_0_xx_1;
			end
		end else if (blt) begin
			if (i_br_less || !i_br_equal) begin
				control_word = 16'b1_010_0_1_1_0000_0_0_xx_1;
			end else begin
				control_word = 16'b0_010_0_1_1_0000_0_0_xx_1;
			end
		end else if (bge) begin
			if (!i_br_less) begin
				control_word = 16'b1_010_0_1_1_0000_0_0_xx_1;
			end else begin
				control_word = 16'b0_010_0_1_1_0000_0_0_xx_1;
			end
		end else if (bltu) begin
			if (i_br_less || !i_br_equal) begin 
				control_word = 16'b1_010_1_1_1_0000_0_0_xx_1;
			end else begin
				control_word = 16'b0_010_1_1_1_0000_0_0_xx_1;
			end
		end else if (bgeu) begin
			if (!i_br_less) begin
				control_word = 16'b1_010_1_1_1_0000_0_0_xx_1;
			end else begin
				control_word = 16'b0_010_1_1_1_0000_0_0_xx_1;
			end
		end 
	end

	
endmodule