`timescale 1ns/1ps

module brc_tb;

    // =========================================================
    // DUT signals
    // =========================================================

    logic [31:0] i_rs1_data;
    logic [31:0] i_rs2_data;
    logic        i_br_un;

    logic        o_br_less;
    logic        o_br_equal;


    // =========================================================
    // Instantiate DUT
    // =========================================================

    brc dut (
        .i_rs1_data (i_rs1_data),
        .i_rs2_data (i_rs2_data),
        .i_br_un    (i_br_un),
        .o_br_less  (o_br_less),
        .o_br_equal (o_br_equal)
    );


    // =========================================================
    // Reference model
    //
    // Built-in comparison operators are used ONLY
    // for verification.
    // =========================================================

    function automatic logic expected_less (
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        br_un
    );

        logic signed [31:0] signed_a;
        logic signed [31:0] signed_b;

        begin

            signed_a = a;
            signed_b = b;

            if (br_un)
                expected_less = (signed_a < signed_b);
            else
                expected_less = (a < b);

        end

    endfunction


    function automatic logic expected_equal (
        input logic [31:0] a,
        input logic [31:0] b
    );

        begin
            expected_equal = (a == b);
        end

    endfunction


    // =========================================================
    // Check one testcase
    // =========================================================

    task automatic check_case (
        input logic [31:0] a,
        input logic [31:0] b,
        input logic        br_un
    );

        logic expected_less_value;
        logic expected_equal_value;

        begin

            i_rs1_data = a;
            i_rs2_data = b;
            i_br_un    = br_un;

            #1;

            expected_less_value =
                expected_less(a, b, br_un);

            expected_equal_value =
                expected_equal(a, b);


            assert (o_br_less === expected_less_value)
            else begin
                $error("LESS FAIL: rs1=%h rs2=%h br_un=%b expected=%b actual=%b",
                    a, b, br_un,
                    expected_less_value, o_br_less);
            end

            assert (o_br_equal === expected_equal_value)
            else begin
                $error("EQUAL FAIL: rs1=%h rs2=%h expected=%b actual=%b",
                    a, b,
                    expected_equal_value, o_br_equal);
            end

        end

    endtask


    // =========================================================
    // Test
    // =========================================================

    initial begin

        $dumpfile("sim/module/brc_tb.vcd");
        $dumpvars(0, brc_tb);

        $display("==========================================");
        $display("            BRC TESTBENCH");
        $display("==========================================");


        // =====================================================
        // 1. UNSIGNED TEST
        // =====================================================

        $display("\n[1] UNSIGNED TEST");


        // 5 < 10
        check_case(
            32'd5,
            32'd10,
            1'b0
        );


        // 10 < 5 -> false
        check_case(
            32'd10,
            32'd5,
            1'b0
        );


        // 5 = 5
        check_case(
            32'd5,
            32'd5,
            1'b0
        );


        // 0 < FFFFFFFF
        check_case(
            32'h00000000,
            32'hFFFFFFFF,
            1'b0
        );


        // FFFFFFFF < 0 -> false
        check_case(
            32'hFFFFFFFF,
            32'h00000000,
            1'b0
        );


        // =====================================================
        // 2. SIGNED TEST
        // =====================================================

        $display("\n[2] SIGNED TEST");


        // +5 < +10
        check_case(
            32'd5,
            32'd10,
            1'b1
        );


        // +10 < +5 -> false
        check_case(
            32'd10,
            32'd5,
            1'b1
        );


        // -1 < +1
        check_case(
            32'hFFFFFFFF,
            32'h00000001,
            1'b1
        );


        // +1 < -1 -> false
        check_case(
            32'h00000001,
            32'hFFFFFFFF,
            1'b1
        );


        // -10 < -5
        check_case(
            32'hFFFFFFF6,
            32'hFFFFFFFB,
            1'b1
        );


        // -5 < -10 -> false
        check_case(
            32'hFFFFFFFB,
            32'hFFFFFFF6,
            1'b1
        );


        // -1 = -1
        check_case(
            32'hFFFFFFFF,
            32'hFFFFFFFF,
            1'b1
        );


        // 0 = 0
        check_case(
            32'h00000000,
            32'h00000000,
            1'b1
        );


        // =====================================================
        // 3. IMPORTANT SIGN DIFFERENCE TEST
        // =====================================================

        $display("\n[3] SIGN DIFFERENCE TEST");


        // Same numbers, unsigned vs signed
        //
        // FFFFFFFF:
        //   unsigned = 4294967295
        //   signed   = -1
        //
        // Compare with 1.

        // Unsigned: FFFFFFFF < 1 = false
        check_case(
            32'hFFFFFFFF,
            32'h00000001,
            1'b0
        );

        // Signed: -1 < 1 = true
        check_case(
            32'hFFFFFFFF,
            32'h00000001,
            1'b1
        );


        // =====================================================
        // 4. BOUNDARY VALUES
        // =====================================================

        $display("\n[4] BOUNDARY VALUES");


        // Signed INT_MIN < 0
        check_case(
            32'h80000000,
            32'h00000000,
            1'b1
        );


        // 0 < INT_MAX
        check_case(
            32'h00000000,
            32'h7FFFFFFF,
            1'b1
        );


        // INT_MAX < INT_MIN -> false
        check_case(
            32'h7FFFFFFF,
            32'h80000000,
            1'b1
        );


        // Unsigned 0 < INT_MIN representation
        check_case(
            32'h00000000,
            32'h80000000,
            1'b0
        );


        // Unsigned INT_MIN representation < 0 -> false
        check_case(
            32'h80000000,
            32'h00000000,
            1'b0
        );


        // =====================================================
        // 5. RANDOMIZED TEST
        // =====================================================

        $display("\n[5] RANDOMIZED TEST");

        repeat (1000) begin

            check_case(
                $urandom,
                $urandom,
                1'b0
            );

            check_case(
                $urandom,
                $urandom,
                1'b1
            );

        end


        // =====================================================
        // Finish
        // =====================================================

        $display("\n==========================================");
        $display("         BRC TEST COMPLETED");
        $display("==========================================");

        $finish;

    end

endmodule