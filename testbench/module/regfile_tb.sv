`timescale 1ns/1ps

module regfile_tb;

    // DUT inputs
    logic        i_clk;
    logic        i_rstn;
    logic [4:0]  i_rs1_addr;
    logic [4:0]  i_rs2_addr;
    logic [4:0]  i_rd_addr;
    logic [31:0] i_rd_data;
    logic        i_rd_wren;

    // DUT outputs
    logic [31:0] o_rs1_data;
    logic [31:0] o_rs2_data;

    integer pass_count;
    integer fail_count;

    // =========================================
    // DUT
    // =========================================
    regfile dut (
        .i_clk       (i_clk),
        .i_rstn      (i_rstn),
        .i_rs1_addr  (i_rs1_addr),
        .i_rs2_addr  (i_rs2_addr),
        .i_rd_addr   (i_rd_addr),
        .i_rd_data   (i_rd_data),
        .i_rd_wren   (i_rd_wren),
        .o_rs1_data  (o_rs1_data),
        .o_rs2_data  (o_rs2_data)
    );

    // Clock period = 10 ns
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    // Waveform
    initial begin
        $dumpfile("sim/module/regfile_tb.vcd");
        $dumpvars(0, regfile_tb);
    end

    // =========================================
    // Task: Check both read ports
    // =========================================
    task automatic check_pair (
        input string       test_name,
        input logic [31:0] expected_rs1,
        input logic [31:0] expected_rs2
    );
    begin
        if ((o_rs1_data !== expected_rs1) ||
            (o_rs2_data !== expected_rs2)) begin

            fail_count = fail_count + 1;

            $display("[FAIL] %s", test_name);
            $display("       RS1: expected=%08h actual=%08h",
                     expected_rs1, o_rs1_data);
            $display("       RS2: expected=%08h actual=%08h",
                     expected_rs2, o_rs2_data);
        end
        else begin
            pass_count = pass_count + 1;

            $display("[PASS] %s", test_name);
            $display("       RS1=%08h RS2=%08h",
                     o_rs1_data, o_rs2_data);
        end
    end
    endtask

    // =========================================
    // Task: Write a register at rising edge
    // =========================================
    task automatic write_reg (
        input logic [4:0]  addr,
        input logic [31:0] data,
        input logic        write_enable,
        input string       test_name
    );
    begin
        // Drive inputs before rising edge
        @(negedge i_clk);

        i_rd_addr = addr;
        i_rd_data = data;
        i_rd_wren = write_enable;

        // Synchronous write
        @(posedge i_clk);
        #1;

        $display(
            "[WRITE] %s | x%0d = %08h | wren=%b",
            test_name, addr, data, write_enable
        );

        // Disable write after the edge
        i_rd_wren = 1'b0;
    end
    endtask

    // =========================================
    // Test sequence
    // =========================================
    initial begin
        // Initialize inputs
        i_rstn      = 1'b1;
        i_rs1_addr  = 5'd0;
        i_rs2_addr  = 5'd0;
        i_rd_addr   = 5'd0;
        i_rd_data   = 32'd0;
        i_rd_wren   = 1'b0;

        pass_count = 0;
        fail_count = 0;

        // Initial asynchronous reset
        #1;
        i_rstn = 1'b0;
        #2;
        @(negedge i_clk);
        i_rstn = 1'b1;

        // =========================================
        // TC1: Write and Read x1
        // x1 = 0x12345678
        // =========================================
        write_reg(
            5'd1,
            32'h12345678,
            1'b1,
            "TC1: Write x1"
        );

        i_rs1_addr = 5'd1;
        i_rs2_addr = 5'd0;
        #1;

        check_pair(
            "TC1: Read x1",
            32'h12345678,
            32'h00000000
        );

        // =========================================
        // TC2: Write and Read x31
        // x31 = 0xAABBCCDD
        // =========================================
        write_reg(
            5'd31,
            32'hAABBCCDD,
            1'b1,
            "TC2: Write x31"
        );

        i_rs1_addr = 5'd0;
        i_rs2_addr = 5'd31;
        #1;

        check_pair(
            "TC2: Read x31",
            32'h00000000,
            32'hAABBCCDD
        );

        // =========================================
        // TC3: Write and Read x0
        // Write to x0 must be ignored
        // =========================================
        write_reg(
            5'd0,
            32'hFFFFFFFF,
            1'b1,
            "TC3: Attempt Write x0"
        );

        i_rs1_addr = 5'd0;
        i_rs2_addr = 5'd0;
        #1;

        check_pair(
            "TC3: x0 Always Zero",
            32'h00000000,
            32'h00000000
        );

        // =========================================
        // TC4: Read Dual Port
        // x1 = 0x12345678
        // x31 = 0xAABBCCDD
        // =========================================
        i_rs1_addr = 5'd1;
        i_rs2_addr = 5'd31;
        #1;

        check_pair(
            "TC4: Dual Read Ports",
            32'h12345678,
            32'hAABBCCDD
        );

        // =========================================
        // TC5: Write Enable Disabled
        // x1 must retain 0x12345678
        // =========================================
        write_reg(
            5'd1,
            32'h11111111,
            1'b0,
            "TC5: Write Enable Disabled"
        );

        i_rs1_addr = 5'd1;
        i_rs2_addr = 5'd31;
        #1;

        check_pair(
            "TC5: x1 Retains Old Value",
            32'h12345678,
            32'hAABBCCDD
        );

        // =========================================
        // TC6: Same Register on Both Ports
        // x3 = 0x87654321
        // =========================================
        write_reg(
            5'd3,
            32'h87654321,
            1'b1,
            "TC6: Write x3"
        );

        i_rs1_addr = 5'd3;
        i_rs2_addr = 5'd3;
        #1;

        check_pair(
            "TC6: Same Register on Both Ports",
            32'h87654321,
            32'h87654321
        );

        // =========================================
        // TC7: Asynchronous Read
        // Change RS1 address from x1 to x3
        // while clock remains low.
        // =========================================
        @(negedge i_clk);

        i_rs1_addr = 5'd1;
        i_rs2_addr = 5'd3;
        #1;

        check_pair(
            "TC7a: Read x1 Before Address Change",
            32'h12345678,
            32'h87654321
        );

        // Change address WITHOUT a rising clock edge
        i_rs1_addr = 5'd3;
        #1;

        check_pair(
            "TC7b: RS1 Updates Without Clock",
            32'h87654321,
            32'h87654321
        );

        // =========================================
        // Prepare x8 and x16 for reset testcase
        // =========================================
        write_reg(
            5'd8,
            32'h88888888,
            1'b1,
            "Prepare x8 for Reset"
        );

        write_reg(
            5'd16,
            32'h16161616,
            1'b1,
            "Prepare x16 for Reset"
        );

        // =========================================
        // TC8: Asynchronous Reset
        // Assert reset between clock edges
        // =========================================
        @(negedge i_clk);

        i_rd_wren = 1'b0;

        // Assert reset while clock is low
        #1;
        i_rstn = 1'b0;
        #1;

        // Check x1 and x8
        i_rs1_addr = 5'd1;
        i_rs2_addr = 5'd8;
        #1;

        check_pair(
            "TC8a: Reset Clears x1 and x8",
            32'h00000000,
            32'h00000000
        );

        // Check x16 and x31
        i_rs1_addr = 5'd16;
        i_rs2_addr = 5'd31;
        #1;

        check_pair(
            "TC8b: Reset Clears x16 and x31",
            32'h00000000,
            32'h00000000
        );

        // =========================================
        // Summary
        // =========================================
        $display("");
        $display("========================================");
        $display("          REGFILE TEST SUMMARY");
        $display("========================================");
        $display("Total checks : %0d",
                 pass_count + fail_count);
        $display("PASS         : %0d", pass_count);
        $display("FAIL         : %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TESTS FAILED");

        $finish;
    end

endmodule