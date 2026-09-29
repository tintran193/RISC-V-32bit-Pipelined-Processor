`timescale 1ns/1ps

module alu_tb;

    // =========================================================
    // ALU operation encoding
    // Must match alu.sv
    // =========================================================

    localparam logic [3:0] ALU_ADD  = 4'b0000;
    localparam logic [3:0] ALU_SUB  = 4'b0001;
    localparam logic [3:0] ALU_SLT  = 4'b0010;
    localparam logic [3:0] ALU_SLTU = 4'b0011;
    localparam logic [3:0] ALU_XOR  = 4'b0100;
    localparam logic [3:0] ALU_OR   = 4'b0101;
    localparam logic [3:0] ALU_AND  = 4'b0110;
    localparam logic [3:0] ALU_SLL  = 4'b0111;
    localparam logic [3:0] ALU_SRL  = 4'b1000;
    localparam logic [3:0] ALU_SRA  = 4'b1001;


    // =========================================================
    // DUT signals
    // =========================================================

    logic [31:0] i_op_a;
    logic [31:0] i_op_b;
    logic [3:0]  i_alu_op;

    logic [31:0] o_alu_data;


    // =========================================================
    // Instantiate DUT
    // =========================================================

    alu dut (
        .i_op_a     (i_op_a),
        .i_op_b     (i_op_b),
        .i_alu_op   (i_alu_op),
        .o_alu_data (o_alu_data)
    );


    // =========================================================
    // Reference model
    //
    // Built-in arithmetic/comparison/shift operators are
    // used ONLY for verification.
    // =========================================================

    function automatic logic [31:0] reference_model (
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [3:0]  op
    );

        logic signed [31:0] signed_a;
        logic signed [31:0] signed_b;

        begin

            signed_a = a;
            signed_b = b;

            case (op)

                ALU_ADD:
                    reference_model = a + b;

                ALU_SUB:
                    reference_model = a - b;

                ALU_SLT:
                    reference_model = ($signed(signed_a) <
                                        $signed(signed_b))
                                      ? 32'h00000001
                                      : 32'h00000000;

                ALU_SLTU:
                    reference_model = (a < b)
                                      ? 32'h00000001
                                      : 32'h00000000;

                ALU_XOR:
                    reference_model = a ^ b;

                ALU_OR:
                    reference_model = a | b;

                ALU_AND:
                    reference_model = a & b;

                ALU_SLL:
                    reference_model = a << b[4:0];

                ALU_SRL:
                    reference_model = a >> b[4:0];

                ALU_SRA:
                    reference_model = signed_a >>> b[4:0];

                default:
                    reference_model = 32'h00000000;

            endcase

        end

    endfunction


    // =========================================================
    // Operation name
    // Used only for readable messages
    // =========================================================

    function automatic string op_name (
        input logic [3:0] op
    );

        begin

            case (op)

                ALU_ADD:  op_name = "ADD";
                ALU_SUB:  op_name = "SUB";
                ALU_SLT:  op_name = "SLT";
                ALU_SLTU: op_name = "SLTU";
                ALU_XOR:  op_name = "XOR";
                ALU_OR:   op_name = "OR";
                ALU_AND:  op_name = "AND";
                ALU_SLL:  op_name = "SLL";
                ALU_SRL:  op_name = "SRL";
                ALU_SRA:  op_name = "SRA";

                default:
                    op_name = "UNKNOWN";

            endcase

        end

    endfunction


    // =========================================================
    // Statistics
    // =========================================================

    integer total_tests;
    integer failed_tests;


    // =========================================================
    // Check one ALU testcase
    // =========================================================

    task automatic check_case (
        input logic [31:0] a,
        input logic [31:0] b,
        input logic [3:0]  op
    );

        logic [31:0] expected;

        begin

            i_op_a   = a;
            i_op_b   = b;
            i_alu_op = op;

            #1;

            expected = reference_model(a, b, op);

            total_tests = total_tests + 1;

            assert (o_alu_data === expected)
            else begin

                failed_tests = failed_tests + 1;

                $error(
                    "FAIL: op=%s a=%h b=%h expected=%h actual=%h",
                    op_name(op),
                    a,
                    b,
                    expected,
                    o_alu_data
                );

            end

        end

    endtask


    // =========================================================
    // Main test
    // =========================================================

    initial begin

        $dumpfile("sim/module/alu_tb.vcd");
        $dumpvars(0, alu_tb);

        total_tests  = 0;
        failed_tests = 0;

        $display("==============================================");
        $display("              ALU TESTBENCH");
        $display("==============================================");


        // =====================================================
        // 1. ADD
        // =====================================================

        $display("\n[1] Testing ADD");

        check_case(
            32'h00000000,
            32'h00000000,
            ALU_ADD
        );

        check_case(
            32'h00000001,
            32'h00000002,
            ALU_ADD
        );

        check_case(
            32'h12345678,
            32'h11111111,
            ALU_ADD
        );

        check_case(
            32'hFFFFFFFF,
            32'h00000001,
            ALU_ADD
        );


        // =====================================================
        // 2. SUB
        // =====================================================

        $display("\n[2] Testing SUB");

        check_case(
            32'h00000005,
            32'h00000003,
            ALU_SUB
        );

        check_case(
            32'h00000003,
            32'h00000005,
            ALU_SUB
        );

        check_case(
            32'h00000000,
            32'h00000001,
            ALU_SUB
        );

        check_case(
            32'h80000000,
            32'h00000001,
            ALU_SUB
        );


        // =====================================================
        // 3. XOR
        // =====================================================

        $display("\n[3] Testing XOR");

        check_case(
            32'h00000000,
            32'hFFFFFFFF,
            ALU_XOR
        );

        check_case(
            32'h12345678,
            32'h87654321,
            ALU_XOR
        );


        // =====================================================
        // 4. OR
        // =====================================================

        $display("\n[4] Testing OR");

        check_case(
            32'h00000000,
            32'hFFFFFFFF,
            ALU_OR
        );

        check_case(
            32'h12340000,
            32'h00005678,
            ALU_OR
        );


        // =====================================================
        // 5. AND
        // =====================================================

        $display("\n[5] Testing AND");

        check_case(
            32'hFFFFFFFF,
            32'h12345678,
            ALU_AND
        );

        check_case(
            32'h12345678,
            32'h87654321,
            ALU_AND
        );


        // =====================================================
        // 6. SLT
        // =====================================================

        $display("\n[6] Testing SLT");

        // 5 < 10
        check_case(
            32'h00000005,
            32'h0000000A,
            ALU_SLT
        );

        // 10 < 5 -> false
        check_case(
            32'h0000000A,
            32'h00000005,
            ALU_SLT
        );

        // -1 < +1
        check_case(
            32'hFFFFFFFF,
            32'h00000001,
            ALU_SLT
        );

        // +1 < -1 -> false
        check_case(
            32'h00000001,
            32'hFFFFFFFF,
            ALU_SLT
        );

        // Equal
        check_case(
            32'h12345678,
            32'h12345678,
            ALU_SLT
        );

        // INT_MIN < 0
        check_case(
            32'h80000000,
            32'h00000000,
            ALU_SLT
        );

        // 0 < INT_MAX
        check_case(
            32'h00000000,
            32'h7FFFFFFF,
            ALU_SLT
        );


        // =====================================================
        // 7. SLTU
        // =====================================================

        $display("\n[7] Testing SLTU");

        // 5 < 10
        check_case(
            32'h00000005,
            32'h0000000A,
            ALU_SLTU
        );

        // 10 < 5 -> false
        check_case(
            32'h0000000A,
            32'h00000005,
            ALU_SLTU
        );

        // FFFFFFFF is NOT less than 1 unsigned
        check_case(
            32'hFFFFFFFF,
            32'h00000001,
            ALU_SLTU
        );

        // 1 is less than FFFFFFFF unsigned
        check_case(
            32'h00000001,
            32'hFFFFFFFF,
            ALU_SLTU
        );

        // Equal
        check_case(
            32'h12345678,
            32'h12345678,
            ALU_SLTU
        );


        // =====================================================
        // 8. SLL
        // =====================================================

        $display("\n[8] Testing SLL");

        check_case(
            32'h00000001,
            32'd0,
            ALU_SLL
        );

        check_case(
            32'h00000001,
            32'd1,
            ALU_SLL
        );

        check_case(
            32'h00000001,
            32'd2,
            ALU_SLL
        );

        check_case(
            32'h00000001,
            32'd4,
            ALU_SLL
        );

        check_case(
            32'h00000001,
            32'd8,
            ALU_SLL
        );

        check_case(
            32'h00000001,
            32'd16,
            ALU_SLL
        );

        check_case(
            32'h00000001,
            32'd31,
            ALU_SLL
        );

        check_case(
            32'h12345678,
            32'd13,
            ALU_SLL
        );


        // =====================================================
        // 9. SRL
        // =====================================================

        $display("\n[9] Testing SRL");

        check_case(
            32'h80000000,
            32'd0,
            ALU_SRL
        );

        check_case(
            32'h80000000,
            32'd1,
            ALU_SRL
        );

        check_case(
            32'h80000000,
            32'd4,
            ALU_SRL
        );

        check_case(
            32'h80000000,
            32'd8,
            ALU_SRL
        );

        check_case(
            32'h80000000,
            32'd16,
            ALU_SRL
        );

        check_case(
            32'h80000000,
            32'd31,
            ALU_SRL
        );

        check_case(
            32'h87654321,
            32'd13,
            ALU_SRL
        );


        // =====================================================
        // 10. SRA
        // =====================================================

        $display("\n[10] Testing SRA");

        // Negative number
        check_case(
            32'h80000000,
            32'd1,
            ALU_SRA
        );

        check_case(
            32'h80000000,
            32'd4,
            ALU_SRA
        );

        check_case(
            32'h80000000,
            32'd8,
            ALU_SRA
        );

        check_case(
            32'h80000000,
            32'd16,
            ALU_SRA
        );

        check_case(
            32'h80000000,
            32'd31,
            ALU_SRA
        );

        check_case(
            32'h87654321,
            32'd13,
            ALU_SRA
        );

        // Positive number
        check_case(
            32'h12345678,
            32'd4,
            ALU_SRA
        );

        check_case(
            32'h12345678,
            32'd16,
            ALU_SRA
        );


        // =====================================================
        // 11. Randomized testing
        // =====================================================

        $display("\n[11] Randomized testing");

        repeat (1000) begin

            // Random ADD
            check_case(
                $urandom,
                $urandom,
                ALU_ADD
            );

            // Random SUB
            check_case(
                $urandom,
                $urandom,
                ALU_SUB
            );

            // Random SLT
            check_case(
                $urandom,
                $urandom,
                ALU_SLT
            );

            // Random SLTU
            check_case(
                $urandom,
                $urandom,
                ALU_SLTU
            );

            // Random XOR
            check_case(
                $urandom,
                $urandom,
                ALU_XOR
            );

            // Random OR
            check_case(
                $urandom,
                $urandom,
                ALU_OR
            );

            // Random AND
            check_case(
                $urandom,
                $urandom,
                ALU_AND
            );

            // Random SLL
            check_case(
                $urandom,
                $urandom_range(0, 31),
                ALU_SLL
            );

            // Random SRL
            check_case(
                $urandom,
                $urandom_range(0, 31),
                ALU_SRL
            );

            // Random SRA
            check_case(
                $urandom,
                $urandom_range(0, 31),
                ALU_SRA
            );

        end


        // =====================================================
        // Final result
        // =====================================================

        $display("\n==============================================");
        $display("Total tests : %0d", total_tests);
        $display("Failed tests: %0d", failed_tests);

        if (failed_tests == 0)
            $display("ALU TEST: PASS");
        else
            $display("ALU TEST: FAIL");

        $display("==============================================");

        $finish;

    end

endmodule