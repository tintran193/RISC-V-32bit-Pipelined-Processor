`timescale 1ns/1ps

module regfile_tb;

    // =========================================================
    // DUT signals
    // =========================================================
    logic        i_clk;
    logic        i_rstn;

    logic [4:0]  i_rs1_addr;
    logic [4:0]  i_rs2_addr;

    logic [4:0]  i_rd_addr;
    logic [31:0] i_rd_data;
    logic        i_rd_wren;

    logic [31:0] o_rs1_data;
    logic [31:0] o_rs2_data;

    integer errors;
    integer idx;
    integer addr2;

    logic [31:0] expected1;
    logic [31:0] expected2;

    // =========================================================
    // DUT
    // =========================================================
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

    // =========================================================
    // Clock: period = 10 ns
    // =========================================================
    initial begin
        i_clk = 1'b0;
        forever #5 i_clk = ~i_clk;
    end

    // =========================================================
    // Task: write one register
    //
    // Drive signals at falling edge.
    // Register is written at rising edge.
    // =========================================================
    task write_reg;
        input [4:0]  addr;
        input [31:0] data;

        begin
            @(negedge i_clk);

            i_rd_addr = addr;
            i_rd_data = data;
            i_rd_wren = 1'b1;

            @(posedge i_clk);
            #1;

            i_rd_wren = 1'b0;
        end
    endtask

    // =========================================================
    // Task: check both read ports
    //
    // Read is asynchronous, so no clock edge is required.
    // =========================================================
    task check_reads;
        input [4:0]  addr1;
        input [31:0] exp1;

        input [4:0]  addr2;
        input [31:0] exp2;

        begin
            i_rs1_addr = addr1;
            i_rs2_addr = addr2;

            #1;

            if (o_rs1_data !== exp1) begin
                $display(
                    "FAIL RS1: addr=%0d expected=%h actual=%h",
                    addr1, exp1, o_rs1_data
                );
                errors = errors + 1;
            end

            if (o_rs2_data !== exp2) begin
                $display(
                    "FAIL RS2: addr=%0d expected=%h actual=%h",
                    addr2, exp2, o_rs2_data
                );
                errors = errors + 1;
            end
        end
    endtask

    // =========================================================
    // Main test
    // =========================================================
    initial begin

        $dumpfile("sim/module/regfile_tb.vcd");
        $dumpvars(0, regfile_tb);

        errors = 0;

        i_rstn     = 1'b1;

        i_rs1_addr = 5'd0;
        i_rs2_addr = 5'd0;

        i_rd_addr  = 5'd0;
        i_rd_data  = 32'b0;
        i_rd_wren  = 1'b0;

        // =====================================================
        // TEST 1: Asynchronous active-low reset
        // =====================================================

        // Select ordinary registers before asserting reset.
        i_rs1_addr = 5'd1;
        i_rs2_addr = 5'd31;

        // Assert reset between clock edges.
        // No rising clock edge occurs before the check.
        #1;
        i_rstn = 1'b0;

        #1;

        if ((o_rs1_data !== 32'b0) ||
            (o_rs2_data !== 32'b0)) begin

            $display(
                "FAIL RESET: rs1=%h rs2=%h",
                o_rs1_data, o_rs2_data
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS TEST 1: Asynchronous reset");
        end

        // Release reset before the next rising edge.
        i_rstn = 1'b1;

        // =====================================================
        // TEST 2: Write x1 to x31
        // =====================================================

        // Each register receives a unique value:
        // x1  = A5000001
        // x2  = A5000002
        // ...
        // x31 = A500001F

        for (idx = 1; idx < 32; idx = idx + 1) begin
            write_reg(idx, 32'hA5000000 | idx);
        end

        $display("PASS TEST 2: Write x1 to x31");

        // =====================================================
        // TEST 3: Read every register
        // =====================================================

        for (idx = 0; idx < 32; idx = idx + 1) begin

            addr2 = 31 - idx;

            // Expected data for read port 1
            if (idx == 0)
                expected1 = 32'b0;
            else
                expected1 = 32'hA5000000 | idx;

            // Expected data for read port 2
            if (addr2 == 0)
                expected2 = 32'b0;
            else
                expected2 = 32'hA5000000 | addr2;

            check_reads(
                idx, expected1,
                addr2, expected2
            );

        end

        $display("Completed TEST 3: Read all registers");

        // =====================================================
        // TEST 4: Both read ports access different registers
        // =====================================================

        check_reads(
            5'd5,  32'hA5000005,
            5'd10, 32'hA500000A
        );

        check_reads(
            5'd31, 32'hA500001F,
            5'd1,  32'hA5000001
        );

        $display("Completed TEST 4: Independent read ports");

        // =====================================================
        // TEST 5: x0 must always return zero
        // =====================================================

        // Attempt to write a nonzero value into x0.
        write_reg(5'd0, 32'hDEADBEEF);

        check_reads(
            5'd0, 32'b0,
            5'd0, 32'b0
        );

        // Verify the attempted write did not affect x5.
        check_reads(
            5'd5, 32'hA5000005,
            5'd0, 32'b0
        );

        $display("Completed TEST 5: x0 is always zero");

        // =====================================================
        // TEST 6: Write enable disabled
        // =====================================================

        // Attempt to change x5 while write enable is low.
        @(negedge i_clk);

        i_rd_addr = 5'd5;
        i_rd_data = 32'hDEADBEEF;
        i_rd_wren = 1'b0;

        @(posedge i_clk);
        #1;

        check_reads(
            5'd5, 32'hA5000005,
            5'd10, 32'hA500000A
        );

        $display("Completed TEST 6: Write disabled");

        // =====================================================
        // TEST 7: Asynchronous read between clock edges
        // =====================================================

        @(negedge i_clk);

        i_rs1_addr = 5'd5;
        i_rs2_addr = 5'd10;

        // This check occurs before the next rising edge.
        #1;

        if ((o_rs1_data !== 32'hA5000005) ||
            (o_rs2_data !== 32'hA500000A)) begin

            $display(
                "FAIL ASYNC READ: rs1=%h rs2=%h",
                o_rs1_data, o_rs2_data
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS TEST 7: Asynchronous read");
        end

        // Change both read addresses again, still before
        // the next rising clock edge.
        i_rs1_addr = 5'd31;
        i_rs2_addr = 5'd1;

        #1;

        if ((o_rs1_data !== 32'hA500001F) ||
            (o_rs2_data !== 32'hA5000001)) begin

            $display(
                "FAIL ASYNC ADDRESS CHANGE: rs1=%h rs2=%h",
                o_rs1_data, o_rs2_data
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS: Read data follows address without clock");
        end

        // =====================================================
        // TEST 8: Reset clears stored data asynchronously
        // =====================================================

        @(negedge i_clk);
        #1;

        // Assert reset before the next rising edge.
        i_rstn = 1'b0;

        i_rs1_addr = 5'd5;
        i_rs2_addr = 5'd10;

        #1;

        if ((o_rs1_data !== 32'b0) ||
            (o_rs2_data !== 32'b0)) begin

            $display(
                "FAIL ASYNC RESET: rs1=%h rs2=%h",
                o_rs1_data, o_rs2_data
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS TEST 8: Reset clears registers asynchronously");
        end

        // Keep reset active through a rising edge,
        // then release at a falling edge.
        @(negedge i_clk);
        i_rstn = 1'b1;

        // Verify that previously stored data was cleared.
        check_reads(
            5'd5,  32'b0,
            5'd10, 32'b0
        );

        check_reads(
            5'd31, 32'b0,
            5'd0,  32'b0
        );

        $display("Completed TEST 8: Reset clears register contents");

        // =====================================================
        // SUMMARY
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin
            $display("REGFILE TEST PASSED");
        end
        else begin
            $display("REGFILE TEST FAILED: %0d error(s)", errors);
            $fatal(1, "Regfile verification failed");
        end

        $display("========================================");

        $finish;

    end

endmodule