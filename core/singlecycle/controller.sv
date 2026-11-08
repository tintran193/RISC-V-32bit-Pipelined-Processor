module controller (
	input logic i_rstn,
    input logic [31:0] i_instr,
    input logic i_br_equal,
    input logic i_br_less,

    output logic o_pc_sel,
    output logic [2:0] o_imm_sel,
    output logic o_rd_wren,
    output logic o_br_un,
    output logic o_opa_sel,
    output logic o_opb_sel,
    output logic [3:0] o_alu_op,
    output logic o_mem_wren,
    output logic [1:0] o_wb_sel,
    output logic o_db_valid
);

    logic RV32;
    logic R_type, S_type, B_type, I_type, I_load_type, J_type; 
    logic JALR_type, LUI_type, AUIPC_type;

// Opcode Decoding
    assign RV32 = i_instr[0] & i_instr[1]; // RV = 11
	assign R_type = (i_instr[6:2] == 5'b01100) & RV32; //R-type = 0110011
	assign S_type = (i_instr[6:2] == 5'b01000) & RV32; //S-type = 0100011
	assign B_type = (i_instr[6:2] == 5'b11000) & RV32; //B-type = 1100011
	assign I_type = (i_instr[6:2] == 5'b00100) & RV32; //I-type = 0010011
	assign I_load_type = (i_instr[6:2] == 5'b00000) & RV32; //I-type (load) = 0000011
	assign JALR_type = (i_instr[6:2] == 5'b11001) & RV32; //JALR = 1100111
	assign J_type = (i_instr[6:2] == 5'b11011) & RV32; //J-type = 1101111
	assign LUI_type = (i_instr[6:2] == 5'b01101) & RV32; //LUI = 0110111
	assign AUIPC_type = (i_instr[6:2] == 5'b00101) & RV32; //AUIPC = 0010111

 // Function Decoding
    logic add, sub, sll, slt, sltu, xor_r, srl, sra, or_r, and_r ; 
	logic sb, sh, sw; 
	logic beq, bne, blt, bge, bltu, bgeu;
	logic slli, srli, srai; 
	logic lb, lh, lw, lbu, lhu;
	logic addi, slti, sltiu, xori, ori, andi; 
	logic jalr, jal;
	logic lui, auipc;

	logic funct7_normal;
	logic funct7_sub;

	assign funct7_normal = (i_instr[31:25] == 7'b0000000);
	assign funct7_sub    = (i_instr[31:25] == 7'b0100000);

    //R-type
    assign add 		= funct7_normal & (i_instr[14:12] == 3'b000) & R_type; 
	assign sub   	= funct7_sub    & (i_instr[14:12] == 3'b000) & R_type;

	assign sll 		= funct7_normal & (i_instr[14:12] == 3'b001) & R_type; 
	assign slt 		= funct7_normal & (i_instr[14:12] == 3'b010) & R_type; 
	assign sltu		= funct7_normal & (i_instr[14:12] == 3'b011) & R_type; 
	assign xor_r 	= funct7_normal & (i_instr[14:12] == 3'b100) & R_type;

	assign srl	    = funct7_normal & (i_instr[14:12] == 3'b101) & R_type; 
	assign sra 		= funct7_sub    & (i_instr[14:12] == 3'b101) & R_type;

	assign or_r	   = funct7_normal & (i_instr[14:12] == 3'b110) & R_type; 
	assign and_r   = funct7_normal & (i_instr[14:12] == 3'b111) & R_type;

    //S_type 
	assign sb = (i_instr[14:12] == 3'b000) & S_type; 
	assign sh = (i_instr[14:12] == 3'b001) & S_type; 
	assign sw = (i_instr[14:12] == 3'b010) & S_type; 
	
    //B_type 
	assign beq 	= (i_instr[14:12] == 3'b000) & B_type;
	assign bne	= (i_instr[14:12] == 3'b001) & B_type; 
	assign blt	= (i_instr[14:12] == 3'b100) & B_type; 
	assign bge 	= (i_instr[14:12] == 3'b101) & B_type; 
	assign bltu = (i_instr[14:12] == 3'b110) & B_type; 
	assign bgeu = (i_instr[14:12] == 3'b111) & B_type; 
	
    //I_type shift 
	assign slli = funct7_normal &  (i_instr[14:12] == 3'b001) & I_type; 
	assign srli = funct7_normal &  (i_instr[14:12] == 3'b101) & I_type;
	assign srai = funct7_sub    &  (i_instr[14:12] == 3'b101) & I_type; 
	
    //I_type_load  
	assign lb  = (i_instr[14:12] == 3'b000) & I_load_type; 
	assign lh  = (i_instr[14:12] == 3'b001) & I_load_type; 
	assign lw  = (i_instr[14:12] == 3'b010) & I_load_type; 
	assign lbu = (i_instr[14:12] == 3'b100) & I_load_type; 
	assign lhu = (i_instr[14:12] == 3'b101) & I_load_type; 
	
    //I_type 
	assign addi  = (i_instr[14:12] == 3'b000) & I_type; 
	assign slti  = (i_instr[14:12] == 3'b010) & I_type; 
	assign sltiu = (i_instr[14:12] == 3'b011) & I_type; 
	assign xori  = (i_instr[14:12] == 3'b100) & I_type; 
	assign ori   = (i_instr[14:12] == 3'b110) & I_type; 
	assign andi  = (i_instr[14:12] == 3'b111) & I_type; 
	
    //JALR
	assign jalr = (i_instr[14:12] == 3'b000) & JALR_type;

    //J_type 
	assign jal  = J_type; 
	
    //U_type
	assign lui = LUI_type;
	assign auipc = AUIPC_type;

// Control signal
    logic [15:0] control_signal;
	logic ctrl_db_valid;
    assign {o_pc_sel, o_imm_sel, o_br_un, 
            o_opa_sel, o_opb_sel, o_alu_op, o_rd_wren, o_mem_wren, o_wb_sel, ctrl_db_valid} = control_signal;
	
always_comb begin
	control_signal = 16'd0;

	if (i_rstn) begin	
//R_type 	
		if (add) begin
			control_signal = 16'b0_000_0_0_0_0000_1_0_01_1;
		end else if (sub) begin
			control_signal = 16'b0_000_0_0_0_0001_1_0_01_1; 
		end else if (sll) begin
			control_signal = 16'b0_000_0_0_0_0111_1_0_01_1; 
		end else if (slt) begin
			control_signal = 16'b0_000_0_0_0_0010_1_0_01_1; 
		end else if (sltu) begin
			control_signal = 16'b0_000_0_0_0_0011_1_0_01_1;
		end else if (xor_r) begin
			control_signal = 16'b0_000_0_0_0_0100_1_0_01_1;
		end else if (srl) begin
			control_signal = 16'b0_000_0_0_0_1000_1_0_01_1;
		end else if (sra) begin
			control_signal = 16'b0_000_0_0_0_1001_1_0_01_1;
		end else if (or_r) begin
			control_signal = 16'b0_000_0_0_0_0101_1_0_01_1;
		end else if (and_r) begin
			control_signal = 16'b0_000_0_0_0_0110_1_0_01_1;
	
//Store
		end else if (sb || sh || sw) begin
			control_signal = 16'b0_001_0_0_1_0000_0_1_00_1;
		
		
//I_type 
		end else if (slli) begin
			control_signal = 16'b0_000_0_0_1_0111_1_0_01_1;
		end else if (srli) begin
			control_signal = 16'b0_000_0_0_1_1000_1_0_01_1;
		end else if (srai) begin
			control_signal = 16'b0_000_0_0_1_1001_1_0_01_1;
		end else if (addi) begin
			control_signal = 16'b0_000_0_0_1_0000_1_0_01_1;
		end else if (slti) begin
			control_signal = 16'b0_000_0_0_1_0010_1_0_01_1;
		end else if (sltiu) begin
			control_signal = 16'b0_000_0_0_1_0011_1_0_01_1;
		end else if (xori) begin
			control_signal = 16'b0_000_0_0_1_0100_1_0_01_1;
		end else if (ori) begin
		   	control_signal = 16'b0_000_0_0_1_0101_1_0_01_1;
		end else if (andi) begin
		   	control_signal = 16'b0_000_0_0_1_0110_1_0_01_1;
	 
//Load	 
		end else if (lb || lh || lw || lbu || lhu) begin
		   control_signal = 16'b0_000_0_0_1_0000_1_0_00_1;
		
//JALR
		end else if (jalr) begin
			control_signal = 16'b1_000_0_0_1_0000_1_0_10_1;
		
//JAL	
		end else if (jal) begin
			control_signal = 16'b1_011_0_1_1_0000_1_0_10_1;
		
//U_type 
		end else if (lui) begin
			control_signal = 16'b0_100_0_0_1_1010_1_0_01_1;
		end else if (auipc) begin
			control_signal = 16'b0_100_0_1_1_0000_1_0_01_1;
		
//B_type		
		end else if (beq) begin
			if(i_br_equal) begin
				control_signal = 16'b1_010_0_1_1_0000_0_0_00_1;
			end else begin
				control_signal = 16'b0_010_0_1_1_0000_0_0_00_1;
			end
		end else if (bne) begin
			if (!i_br_equal) begin
				control_signal = 16'b1_010_0_1_1_0000_0_0_00_1;
			end else begin
				control_signal = 16'b0_010_0_1_1_0000_0_0_00_1;
			end
		end else if (blt) begin
			if (i_br_less) begin
				control_signal = 16'b1_010_0_1_1_0000_0_0_00_1;
			end else begin // bge
				control_signal = 16'b0_010_0_1_1_0000_0_0_00_1;
			end
		end else if (bge) begin
			if (!i_br_less) begin
				control_signal = 16'b1_010_0_1_1_0000_0_0_00_1;
			end else begin
				control_signal = 16'b0_010_0_1_1_0000_0_0_00_1;
			end
		end else if (bltu) begin
			if (i_br_less) begin 
				control_signal = 16'b1_010_1_1_1_0000_0_0_00_1;
			end else begin
				control_signal = 16'b0_010_1_1_1_0000_0_0_00_1;
			end
		end else if (bgeu) begin
			if (!i_br_less) begin
				control_signal = 16'b1_010_1_1_1_0000_0_0_00_1;
			end else begin
				control_signal = 16'b0_010_1_1_1_0000_0_0_00_1;
			end
		end else begin 
            control_signal = 16'b0; // Invalid instruction
        end
	end else begin
		control_signal = 16'b0; // Reset state
	end
end

	// The specification requires db_valid to remain low during reset.
    assign o_db_valid = i_rstn & ctrl_db_valid;

endmodule