module lsu (
    input logic [2:0] i_funct3,
    input logic [31:0] i_addr, //From alu
    input logic [31:0] i_wdata, //Rs2 data from regfile
    input logic [31:0] i_rdata, //Data from dmem
    input logic i_wren, //From controller

    output logic [31:0] o_ld_data, //Write back to regfile 
    output logic [31:0] o_dmem_addr,
    output logic [31:0] o_dmem_wdata, //Data to dmem
    output logic [3:0] o_dmem_bmsk,
    output logic o_dmem_wren

);

// Format address according to funct3
    logic [31:0] addr;

    always_comb begin
        case(i_funct3)
            3'b001, 3'b101:
                addr = {i_addr[31:1], 1'b0}; //half-word: LH, LHU, SH
            3'b010:
                addr = {i_addr[31:2], 2'b0}; //word: LW, SW
            default:
                addr = i_addr; //byte
        endcase
    end
// Store data to dmem and mask decoding
    logic [31:0] st_data;

    always_comb begin
        o_dmem_wren = 1'b0;
        o_dmem_bmsk = 4'b0;
        st_data = 32'b0;

        if (i_wren) begin
            case (i_funct3)
                3'b000: begin //SB
                    case (addr[1:0])
                        2'b00: begin //Byte 0
                            o_dmem_bmsk = 4'b0001;
                            st_data[7:0] = i_wdata[7:0]; 
                        end
                        2'b01: begin //Byte 1
                            o_dmem_bmsk = 4'b0010;
                            st_data[15:8] = i_wdata[7:0]; 
                        end
                        2'b10: begin //Byte 2
                            o_dmem_bmsk = 4'b0100;
                            st_data[23:16] = i_wdata[7:0]; 
                        end
                        2'b11: begin //Byte 3
                            o_dmem_bmsk = 4'b1000;
                            st_data[31:24] = i_wdata[7:0]; 
                        end                        
                    endcase
                    o_dmem_wren = 1'b1;
                end

                3'b001: begin //SH
                    if(addr[1] == 1'b0) begin //Lower-halfword
                        o_dmem_bmsk = 4'b0011;
                        st_data[15:0] = i_wdata[15:0];
                    end else begin            // Upper-halfword
                        o_dmem_bmsk = 4'b1100; 
                        st_data[31:16] = i_wdata[15:0];
                    end
                    o_dmem_wren = 1'b1;
                end   

                3'b010: begin //SW
                    o_dmem_bmsk = 4'b1111;
                    st_data = i_wdata;
                    o_dmem_wren = 1'b1;
                end

                default: begin
                    o_dmem_bmsk = 4'b0000;
                    st_data = 32'b0;
                    o_dmem_wren = 1'b0;
                end  
            endcase
        end else begin
            o_dmem_bmsk = 4'b0000;
            st_data = 32'b0;
            o_dmem_wren = 1'b0;
        end
    end

// Assign ouput address and data
    assign o_dmem_addr = addr;
    assign o_dmem_wdata = st_data;

// Load data from dmem 
    logic [31:0] raw_data;
    logic [15:0] halfword_data;
    logic [7:0] byte_data;

    assign raw_data = i_rdata;

    always_comb begin // Load halfword
        if (addr[1] == 1'b0) begin
            halfword_data = raw_data[15:0];
        end else begin
            halfword_data = raw_data[31:16];
        end
    end

    always_comb begin // Load byte
        case (addr[1:0]) 
            2'b00: byte_data = raw_data[7:0];
            2'b01: byte_data = raw_data[15:8];
            2'b10: byte_data = raw_data[23:16];
            2'b11: byte_data = raw_data[31:24];
            default: byte_data = 8'b0;
        endcase
    end

    always_comb begin
        case (i_funct3) 
            3'b000: o_ld_data = {{24{byte_data[7]}}, byte_data}; //LB
            3'b001: o_ld_data = {{16{halfword_data[15]}}, halfword_data}; //LH
            3'b010: o_ld_data = raw_data; // LW
            3'b100: o_ld_data = {24'b0, byte_data}; // LBU
            3'b101: o_ld_data = {16'b0, halfword_data}; // LHU
            default: o_ld_data = 32'b0;
        endcase         
    end 
endmodule