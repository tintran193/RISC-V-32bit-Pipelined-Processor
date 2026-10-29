`timescale 1ns/1ps

module adder32_tb;

    // DUT input signals
    logic        i_sub;
    logic [31:0] i_a;
    logic [31:0] i_b;

    // DUT output signals
    logic [31:0] o_sum;
    logic        o_cout;

    // Expected result: {carry_out, sum}
    logic [32:0] expected;

    integer pass_count;
    integer fail_count;
    integer k;

    // Instantiate DUT
    adder32 dut (
        .i_a    (i_a),
        .i_b    (i_b),
        .i_sub  (i_sub),
        .o_sum  (o_sum),
        .o_cout (o_cout)
    );

    // Waveform dump
    initial begin
        $dumpfile("sim/module/adder32_tb.vcd");
        $dumpvars(0, adder32_tb);
    end

    // Run one test case and check the result
    task automatic check_case (
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        sub,
        input string       test_name
    );
    begin
        // Apply inputs
        i_a   = a;
        i_b   = b;
        i_sub = sub;

        // Calculate expected result
        if (sub == 1'b0) begin
            // ADD: A + B
            expected = {1'b0, a} + {1'b0, b};
        end
        else begin
            // SUB: A - B = A + ~B + 1
            expected = {1'b0, a} + {1'b0, ~b} + 33'd1;
        end

        // Wait for combinational logic to settle
        #10;

        // Check sum and carry-out
        if ({o_cout, o_sum} !== expected) begin
            fail_count = fail_count + 1;

            $display("[FAIL] %s", test_name);
            $display("       A        = 0x%08h", a);
            $display("       B        = 0x%08h", b);
            $display("       i_sub    = %b", sub);
            $display("       Expected = 0x%09h", expected);
            $display("       Actual   = 0x%09h",
                     {o_cout, o_sum});
        end
        else begin
            pass_count = pass_count + 1;

            $display("[PASS] %s | A=%08h B=%08h sub=%b result=%09h",
                     test_name, a, b, sub, {o_cout, o_sum});
        end
    end
    endtask

    // Test sequence
    initial begin
        i_a        = 32'b0;
        i_b        = 32'b0;
        i_sub      = 1'b0;
        pass_count = 0;
        fail_count = 0;

        // ========================================
        // ADD TESTS
        // ========================================

        check_case(
            32'h00000001, 32'h00000002, 1'b0,
            "ADD: 1 + 2"
        );

        check_case(
            32'hFFFFFFFF, 32'h00000001, 1'b0,
            "ADD: Carry out"
        );

        // ========================================
        // SUB TESTS
        // ========================================

        check_case(
            32'h00000005, 32'h00000003, 1'b1,
            "SUB: 5 - 3"
        );

        check_case(
            32'h00000003, 32'h00000005, 1'b1,
            "SUB: 3 - 5, borrow"
        );

        check_case(
            32'hFFFFFFFF, 32'hFFFFFFFF, 1'b1,
            "SUB: Equal operands"
        );

        // ========================================
        // SUMMARY
        // ========================================

        $display("");
        $display("======================================");
        $display("         ADDER32 TEST SUMMARY");
        $display("======================================");
        $display("Total tests : %0d", pass_count + fail_count);
        $display("PASS        : %0d", pass_count);
        $display("FAIL        : %0d", fail_count);
        $display("======================================");

        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TESTS FAILED");

        $finish;
    end

endmodule