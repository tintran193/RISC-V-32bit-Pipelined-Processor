module lsu (
    input logic         i_clk, 
    input logic  [2:0]  i_funct3,
    input logic  [31:0] i_dmem_rdata,
    input logic  [31:0] i_dmem_addr,
    input logic  [31:0] i_dmem_wdata,
    input logic         i_dmem_wren,

    output logic [31:0] o_ld_data,
    output logic [31:0] o_dmem_addr,
    output logic [31:0] o_dmem_wdata,
    output logic [3:0]  o_dmem_bmsk,
    output logic        o_dmem_wren  
);

//Định dạng địa chỉ bộ nhớ theo funct3 
    logic [31:0] addr; 

    always_comb begin
        case(i_funct3[1:0])
            2'b10: addr = {i_dmem_addr[31:2], 2'b00}; // word
            2'b01: addr = {i_dmem_addr[31:1], 1'b0}; // halfword
            default: addr = i_dmem_addr; // byte
        endcase 
    end

//Thao tác Store vào bộ nhớ và giải mã mask
    logic [31:0] st_data; 

    always_comb begin
        o_dmem_wren = i_dmem_wren;
        o_dmem_bmsk = 4'b0000;
        st_data = 32'b0;
        case(i_funct3[1:0])
           2'b10: begin // word
                o_dmem_bmsk = 4'b1111;
                st_data = i_dmem_wdata;
            end
           2'b01: begin // halfword
                if (addr[1] == 1'b0) begin
                    o_dmem_bmsk = 4'b0011;
                    st_data[15:0] = i_dmem_wdata[15:0];
                end else begin
                    o_dmem_bmsk = 4'b1100;
                    st_data[31:16] = i_dmem_wdata[15:0];
                end
            end
            default: begin // byte
                case(addr[1:0])
                    2'b00: begin
                        o_dmem_bmsk = 4'b0001;
                        st_data[7:0] = i_dmem_wdata[7:0];
                    end
                    2'b01: begin
                        o_dmem_bmsk = 4'b0010;
                        st_data[15:8] = i_dmem_wdata[7:0];
                    end
                    2'b10: begin
                        o_dmem_bmsk = 4'b0100;
                        st_data[23:16] = i_dmem_wdata[7:0];
                    end
                    2'b11: begin
                        o_dmem_bmsk = 4'b1000;
                        st_data[31:24] = i_dmem_wdata[7:0];
                    end
                endcase
            end  
        endcase
    end 

//Gán địa chỉ và dữ liệu bộ nhớ ra ngoài
    assign o_dmem_addr = addr;
    assign o_dmem_wdata = st_data;


//Thao tác Load từ bộ nhớ và giải mã dữ liệu
    logic [31:0] raw_data;
    logic [15:0] haftword_data;
    logic [7:0] byte_data;

    assign raw_data = i_dmem_rdata;

//Đọc dữ liệu halfword từ bộ nhớ
    always_comb begin
        case(addr[1])
            1'b0: haftword_data = raw_data[15:0];
            1'b1: haftword_data = raw_data[31:16];
            default: haftword_data = 16'b0;
        endcase
    end

//Đọc dữ liệu byte từ bộ nhớ
    always_comb begin
        case(addr[1:0])
            2'b00: byte_data = raw_data[7:0];
            2'b01: byte_data = raw_data[15:8];
            2'b10: byte_data = raw_data[23:16];
            2'b11: byte_data = raw_data[31:24];
            default: byte_data = 8'b0;
        endcase
    end

//Mở rộng dấu và chọn ngõ ra theo funct3
    always_comb begin
        case(i_funct3)
            3'b000: o_ld_data = {{24{byte_data[7]}}, byte_data}; // LB
            3'b001: o_ld_data = {{16{haftword_data[15]}}, haftword_data}; // LH
            3'b010: o_ld_data = raw_data; // LW
            3'b100: o_ld_data = {24'b0, byte_data}; // LBU
            3'b101: o_ld_data = {16'b0, haftword_data}; // LHU
            default: o_ld_data = raw_data; // LWU
        endcase
    end

endmodule