module immgen (
	input logic [31:0]  i_instr, 
	input logic [2:0]   i_imm_sel,
	output logic [31:0] o_imm
);

	localparam logic [2:0] I = 3'b000;
	localparam logic [2:0] S = 3'b001;
	localparam logic [2:0] B = 3'b010;
	localparam logic [2:0] J = 3'b011;
	localparam logic [2:0] U = 3'b100;


//Imm[0]	
	always_comb begin
		case(i_imm_sel)
			I: o_imm[0] = i_instr[20]; 
			S: o_imm[0] = i_instr[7];
			default: o_imm[0] = 1'b0; 
		endcase 
	end
	
//Imm[4:1]
	always_comb begin
		case(i_imm_sel)
			I,J: o_imm[4:1] = i_instr[24:21];
			S,B: o_imm[4:1] = i_instr[11:8];
			U: o_imm[4:1] = 4'b0000;
			default: o_imm[4:1] = 4'b0000;
		endcase
	end
	
//Imm[10:5]
	always_comb begin
		case(i_imm_sel)
			I,S,B,J: o_imm[10:5] = i_instr[30:25];
			U:   		o_imm[10:5] = 6'd0;
			default: o_imm[10:5] = 6'd0;
		endcase
	end
	
//Imm[11] 
		always_comb begin
			case(i_imm_sel)
				I,S: o_imm[11] = i_instr[31];
				B:	  o_imm[11] = i_instr[7];
				J:   o_imm[11] = i_instr[20];
				default: o_imm[11] = 1'b0;
			endcase
		end
	
//Imm[19:12]
	always_comb begin
		case(i_imm_sel)
			J, U:    o_imm[19:12] = i_instr[19:12];
			I,S,B: o_imm[19:12] = {8{i_instr[31]}};
            default: o_imm[19:12] = 8'b0;
		endcase
	end
		
//Imm[31:20]
    always_comb begin
        case(i_imm_sel)
            U: o_imm[31:20] = i_instr[31:20];
            I,S,B,J: o_imm[31:20] = {12{i_instr[31]}};
            default: o_imm [31:20] = 12'b0;
        endcase
    end

endmodule	