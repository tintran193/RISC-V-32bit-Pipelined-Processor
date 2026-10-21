module tb_lsu;

    logic        i_clk;
    logic [2:0]  i_funct3;
    logic [31:0] i_dmem_rdata;
    logic [31:0] i_dmem_addr;
    logic [31:0] i_dmem_wdata;
    logic        i_dmem_wren;

    logic [31:0] o_ld_data;
    logic [31:0] o_dmem_addr;
    logic [31:0] o_dmem_wdata;
    logic [3:0]  o_dmem_bmsk;
    logic        o_dmem_wren;

    integer pass_count = 0;
    integer fail_count = 0;

    // Khoi LSU can kiem tra
    lsu dut (
        .i_clk        (i_clk),
        .i_funct3     (i_funct3),
        .i_dmem_rdata (i_dmem_rdata),
        .i_dmem_addr  (i_dmem_addr),
        .i_dmem_wdata (i_dmem_wdata),
        .i_dmem_wren  (i_dmem_wren),

        .o_ld_data    (o_ld_data),
        .o_dmem_addr  (o_dmem_addr),
        .o_dmem_wdata (o_dmem_wdata),
        .o_dmem_bmsk  (o_dmem_bmsk),
        .o_dmem_wren  (o_dmem_wren)
    );

    // Clock 10 ns
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    // Kiem tra cac ngo ra Store
    task automatic check_store(
        input [255:0] test_name,
        input [31:0]  exp_addr,
        input [31:0]  exp_wdata,
        input [3:0]   exp_bmsk,
        input         exp_wren
    );
    begin
        #1;
        if (o_dmem_addr  !== exp_addr  ||
            o_dmem_wdata !== exp_wdata ||
            o_dmem_bmsk  !== exp_bmsk  ||
            o_dmem_wren  !== exp_wren) begin

            $display("FAIL STORE: %0s", test_name);
            $display("  addr : got=%h expected=%h",
                     o_dmem_addr, exp_addr);
            $display("  wdata: got=%h expected=%h",
                     o_dmem_wdata, exp_wdata);
            $display("  bmsk : got=%b expected=%b",
                     o_dmem_bmsk, exp_bmsk);
            $display("  wren : got=%b expected=%b",
                     o_dmem_wren, exp_wren);
            fail_count = fail_count + 1;
        end
        else begin
            $display("PASS STORE: %0s", test_name);
            pass_count = pass_count + 1;
        end
    end
    endtask

    // Kiem tra ngo ra Load
    task automatic check_load(
        input [255:0] test_name,
        input [31:0]  exp_data
    );
    begin
        #1;
        if (o_ld_data !== exp_data) begin
            $display("FAIL LOAD: %0s", test_name);
            $display("  got=%h expected=%h",
                     o_ld_data, exp_data);
            fail_count = fail_count + 1;
        end
        else begin
            $display("PASS LOAD: %0s", test_name);
            pass_count = pass_count + 1;
        end
    end
    endtask

    initial begin
        $display("================================");
        $display("       LSU TESTBENCH START");
        $display("================================");

        i_clk        = 0;
        i_funct3     = 0;
        i_dmem_rdata = 0;
        i_dmem_addr  = 0;
        i_dmem_wdata = 0;
        i_dmem_wren  = 0;

        // ==========================================
        // PHAN 1: KIEM TRA STORE
        // ==========================================

        // SB tai byte 0
        i_funct3    = 3'b000;
        i_dmem_addr = 32'h8000_0000;
        i_dmem_wdata = 32'h1234_56AB;
        i_dmem_wren = 1;
        check_store("SB byte 0",
                    32'h8000_0000, 32'h0000_00AB,
                    4'b0001, 1'b1);

        // SB tai byte 1
        i_dmem_addr = 32'h8000_0001;
        check_store("SB byte 1",
                    32'h8000_0001, 32'h0000_AB00,
                    4'b0010, 1'b1);

        // SB tai byte 2
        i_dmem_addr = 32'h8000_0002;
        check_store("SB byte 2",
                    32'h8000_0002, 32'h00AB_0000,
                    4'b0100, 1'b1);

        // SB tai byte 3
        i_dmem_addr = 32'h8000_0003;
        check_store("SB byte 3",
                    32'h8000_0003, 32'hAB00_0000,
                    4'b1000, 1'b1);

        // SH tai nua word duoi
        i_funct3 = 3'b001;
        i_dmem_addr = 32'h8000_0000;
        i_dmem_wdata = 32'h1234_ABCD;
        check_store("SH lower halfword",
                    32'h8000_0000, 32'h0000_ABCD,
                    4'b0011, 1'b1);

        // SH tai nua word tren
        i_dmem_addr = 32'h8000_0002;
        check_store("SH upper halfword",
                    32'h8000_0002, 32'hABCD_0000,
                    4'b1100, 1'b1);

        // SW
        i_funct3 = 3'b010;
        i_dmem_addr = 32'h8000_0004;
        i_dmem_wdata = 32'h1234_5678;
        check_store("SW full word",
                    32'h8000_0004, 32'h1234_5678,
                    4'b1111, 1'b1);

        // WREN = 0
        i_dmem_wren = 0;
        check_store("Store disabled",
                    32'h8000_0004, 32'h1234_5678,
                    4'b1111, 1'b0);

        // ==========================================
        // PHAN 2: KIEM TRA LOAD
        // Du lieu mau:
        // byte 3   byte 2   byte 1   byte 0
        //   80       FF       7F       01
        // ==========================================

        i_dmem_rdata = 32'h80FF_7F01;

        // LB: byte 0 = 0x01
        i_funct3 = 3'b000;
        i_dmem_addr = 32'h8000_0000;
        check_load("LB byte 0", 32'h0000_0001);

        // LB: byte 1 = 0x7F
        i_dmem_addr = 32'h8000_0001;
        check_load("LB byte 1", 32'h0000_007F);

        // LB: byte 2 = 0xFF, mo rong dau
        i_dmem_addr = 32'h8000_0002;
        check_load("LB byte 2 signed", 32'hFFFF_FFFF);

        // LB: byte 3 = 0x80, mo rong dau
        i_dmem_addr = 32'h8000_0003;
        check_load("LB byte 3 signed", 32'hFFFF_FF80);

        // LBU: byte 3 = 0x80, mo rong 0
        i_funct3 = 3'b100;
        i_dmem_addr = 32'h8000_0003;
        check_load("LBU byte 3", 32'h0000_0080);

        // LH: halfword duoi = 0x7F01
        i_funct3 = 3'b001;
        i_dmem_addr = 32'h8000_0000;
        check_load("LH lower halfword", 32'h0000_7F01);

        // LH: halfword tren = 0x80FF, mo rong dau
        i_dmem_addr = 32'h8000_0002;
        check_load("LH upper halfword", 32'hFFFF_80FF);

        // LHU: halfword tren = 0x80FF, mo rong 0
        i_funct3 = 3'b101;
        i_dmem_addr = 32'h8000_0002;
        check_load("LHU upper halfword", 32'h0000_80FF);

        // LW: lay du 32 bit
        i_funct3 = 3'b010;
        i_dmem_addr = 32'h8000_0000;
        check_load("LW full word", 32'h80FF_7F01);

        // ==========================================
        // TONG KET
        // ==========================================
        #5;
        $display("================================");
        $display("          TEST SUMMARY");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("================================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        $finish;
    end

endmodule
