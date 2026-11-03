`timescale 1ns/1ps

module tb_milestone2;

    logic clk;
    logic rstn;

    logic print_valid;
    logic [7:0] print_char;

    logic isa_valid;
    logic [31:0] isa_data;

    logic halt;
    logic db_valid;

    integer pass_count;
    integer fail_count;
    integer i;

    // DUT
    milestone2 dut (
        .i_clk         (clk),
        .i_rstn        (rstn),
        .o_print_valid (print_valid),
        .o_print_char  (print_char),
        .o_isa_valid   (isa_valid),
        .o_isa_data    (isa_data),
        .o_halt        (halt),
        .o_db_valid    (db_valid)
    );

    // Clock: 10ns
    always #5 clk = ~clk;

    // Reset
    initial begin
        clk = 0;
        rstn = 0;

        pass_count = 0;
        fail_count = 0;

        #20;
        rstn = 1;
    end

    // Theo doi PC va instruction
    always @(posedge clk) begin
        if (rstn) begin
            #1;
            $display(
                "Time=%0t | PC=%h | Instr=%h | DB_VALID=%b",
                $time,
                dut.u_core.dp.pc,
                dut.imem_core_rdata,
                db_valid
            );
        end
    end

    // Task kiem tra thanh ghi
    task automatic check_reg(
        input integer reg_num,
        input logic [31:0] expected
    );
        logic [31:0] actual;
        begin
            actual = dut.u_core.dp.u_regfile.regs[reg_num];

            if (actual === expected) begin
                $display(
                    "[PASS] x%0d = %h",
                    reg_num, actual
                );
                pass_count = pass_count + 1;
            end
            else begin
                $display(
                    "[FAIL] x%0d | Expected = %h | Actual = %h",
                    reg_num, expected, actual
                );
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Cho CPU chay den vong lap cuoi
    initial begin
        wait (rstn == 1'b1);
        wait (dut.u_core.dp.pc == 32'h800000D0);
        #2;

        $display("\n========================================");
        $display("          REGISTER FILE TEST");
        $display("========================================");

        check_reg(0,  32'h00000000);
        check_reg(1,  32'h12345000);
        check_reg(2,  32'h80001014);
        check_reg(3,  32'h0000000A);
        check_reg(4,  32'h00000003);
        check_reg(5,  32'hFFFFFFFB);
        check_reg(6,  32'h00000005);
        check_reg(7,  32'h0000000D);
        check_reg(8,  32'h00000007);
        check_reg(9,  32'h00000C00);
        check_reg(10, 32'h00000001);
        check_reg(11, 32'h00000000);
        check_reg(12, 32'h00000009);
        check_reg(13, 32'h00000001);
        check_reg(14, 32'hFFFFFFFF);
        check_reg(15, 32'h0000000B);
        check_reg(16, 32'h00000002);
        check_reg(17, 32'h00000001);
        check_reg(18, 32'h00000001);
        check_reg(19, 32'h00000005);
        check_reg(20, 32'h0000000F);
        check_reg(21, 32'h00000002);
        check_reg(22, 32'h0000000C);
        check_reg(23, 32'h00000005);
        check_reg(24, 32'hFFFFFFFD);
        check_reg(25, 32'h80080000);
        check_reg(26, 32'h0000000D);

        // Cac thanh ghi nay bi ghi lai boi JAL/JALR
        check_reg(27, 32'h0000004D);
        check_reg(28, 32'hFFFFFFFB);
        check_reg(29, 32'h800000C8);
        check_reg(30, 32'h800000CC);
        check_reg(31, 32'h800000B8);

        $display("\n========================================");
        $display("              TEST SUMMARY");
        $display("========================================");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);

        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED!");
        else
            $display("RESULT: SOME TESTS FAILED!");

        $display("========================================");

        $finish;
    end

    // Timeout
    initial begin
        #3000;
        $display("[ERROR] CPU TIMEOUT!");
        $display("Current PC = %h", dut.u_core.dp.pc);
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("tb_milestone2.vcd");
        $dumpvars(0, tb_milestone2);
    end

endmodule
