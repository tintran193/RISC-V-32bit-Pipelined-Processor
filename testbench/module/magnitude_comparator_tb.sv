`timescale 1ns/1ps

module magnitude_comparator_tb;

    // DUT inputs
    logic [31:0] i_a;
    logic [31:0] i_b;
    logic        i_unsigned;

    // DUT outputs
    logic o_eq;
    logic o_lt;
    logic o_gt;

    integer pass_count;
    integer fail_count;
    integer k;

    logic [31:0] rand_a;
    logic [31:0] rand_b;

    // Instantiate DUT
    magnitude_comparator dut (
        .i_a        (i_a),
        .i_b        (i_b),
        .i_unsigned (i_unsigned),
        .o_eq       (o_eq),
        .o_lt       (o_lt),
        .o_gt       (o_gt)
    );

    // Waveform dump
    initial begin
        $dumpfile("sim/module/magnitude_comparator_tb.vcd");
        $dumpvars(0, magnitude_comparator_tb);
    end

    // =========================================
    // Task: Apply inputs and check DUT outputs
    // =========================================
    task automatic check_case (
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        unsigned_mode,
        input string       test_name
    );

        logic exp_eq;
        logic exp_lt;
        logic exp_gt;

        begin
            // Apply inputs
            i_a        = a;
            i_b        = b;
            i_unsigned = unsigned_mode;

            // Calculate expected outputs
            exp_eq = (a == b);

            if (unsigned_mode == 1'b1) begin
                // Unsigned comparison
                exp_lt = (a < b);
                exp_gt = (a > b);
            end
            else begin
                // Signed two's-complement comparison
                exp_lt = ($signed(a) < $signed(b));
                exp_gt = ($signed(a) > $signed(b));
            end

            // Wait for combinational logic to settle
            #10;

            // Check all three outputs
            if ({o_eq, o_lt, o_gt} !==
                {exp_eq, exp_lt, exp_gt}) begin

                fail_count = fail_count + 1;

                $display("[FAIL] %s", test_name);
                $display("       A          = 0x%08h", a);
                $display("       B          = 0x%08h", b);
                $display("       i_unsigned = %b", unsigned_mode);

                $display("       Expected: EQ=%b LT=%b GT=%b",
                         exp_eq, exp_lt, exp_gt);

                $display("       Actual:   EQ=%b LT=%b GT=%b",
                         o_eq, o_lt, o_gt);
            end
            else begin
                pass_count = pass_count + 1;

                $display("[PASS] %s | EQ=%b LT=%b GT=%b",
                         test_name, o_eq, o_lt, o_gt);
            end
        end
    endtask

    // =========================================
    // Test sequence
    // =========================================
    initial begin
        i_a        = 32'b0;
        i_b        = 32'b0;
        i_unsigned = 1'b0;

        pass_count = 0;
        fail_count = 0;

        // =====================================
        // 1. Equality
        // =====================================

        check_case(
            32'hFFFFFFFF, 32'hFFFFFFFF, 1'b1,
            "Equal operands - unsigned"
        );

        // =====================================
        // 2. Unsigned comparison
        // =====================================

        check_case(
            32'h00000003, 32'h00000005, 1'b1,
            "Unsigned: A < B"
        );

        check_case(
            32'h00000009, 32'h00000004, 1'b1,
            "Unsigned: A > B"
        );

        // =====================================
        // 3. Signed comparison
        // =====================================

        check_case(
            32'hFFFFFFFF, 32'h00000001, 1'b0,
            "Signed: -1 < +1"
        );

        check_case(
            32'h7FFFFFFF, 32'hFFFFFFFF, 1'b0,
            "Signed: Maximum positive > -1"
        );

        // =====================================
        // 4. Same operands, different modes
        // =====================================

        check_case(
            32'h7FFFFFFF, 32'hFFFFFFFF, 1'b1,
            "Mode test: unsigned "
        );

        // =====================================
        // 5. Random tests
        // =====================================

        for (k = 0; k < 100; k = k + 1) begin
            rand_a = $urandom;
            rand_b = $urandom;

            check_case(
                rand_a, rand_b, 1'b0,
                "Random signed comparison"
            );

            check_case(
                rand_a, rand_b, 1'b1,
                "Random unsigned comparison"
            );
        end

        // =====================================
        // 6. Summary
        // =====================================

        $display("");
        $display("========================================");
        $display("  MAGNITUDE COMPARATOR TEST SUMMARY");
        $display("========================================");
        $display("Total tests : %0d",
                 pass_count + fail_count);
        $display("PASS        : %0d", pass_count);
        $display("FAIL        : %0d", fail_count);
        $display("========================================");

        if (fail_count == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: TESTS FAILED");

        $finish;
    end

endmodule