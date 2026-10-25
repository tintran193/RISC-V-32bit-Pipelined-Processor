`timescale 1ns/1ps

module shifter32_tb;

    // DUT inputs
    logic [31:0] i_data;
    logic [4:0]  i_shamt;
    logic [1:0]  i_mode;

    // DUT output
    logic [31:0] o_data;

    // Test statistics
    integer pass_count;
    integer fail_count;

    // Instantiate DUT
    shifter32 dut (
        .i_data  (i_data),
        .i_shamt (i_shamt),
        .i_mode  (i_mode),
        .o_data  (o_data)
    );

    // Waveform dump
    initial begin
        $dumpfile("sim/module/shifter32_tb.vcd");
        $dumpvars(0, shifter32_tb);
    end

    // Task: apply inputs and verify output
    task automatic check_case (
        input logic [1:0]  mode,
        input logic [31:0] data,
        input logic [4:0]  shamt,
        input logic [31:0] expected,
        input string       test_name
    );
    begin
        // Apply inputs
        i_mode  = mode;
        i_data  = data;
        i_shamt = shamt;

        // Wait for combinational logic to settle
        #10;

        // Compare actual and expected results
        if (o_data !== expected) begin
            fail_count = fail_count + 1;

            $display("[FAIL] %s", test_name);
            $display("       i_mode  = %02b", mode);
            $display("       i_data  = 0x%08h", data);
            $display("       i_shamt = %0d", shamt);
            $display("       Expected = 0x%08h", expected);
            $display("       Actual   = 0x%08h", o_data);
        end
        else begin
            pass_count = pass_count + 1;

            $display("[PASS] %s | mode=%02b data=%08h shamt=%0d result=%08h",
                     test_name, mode, data, shamt, o_data);
        end
    end
    endtask

    // Test sequence
    initial begin
        i_mode     = 2'b00;
        i_data     = 32'b0;
        i_shamt    = 5'b0;
        pass_count = 0;
        fail_count = 0;

        // ========================================
        // 1. SRL - Logical Right Shift
        // ========================================

        check_case(
            2'b00, 32'h12345678, 5'd0,
            32'h12345678,
            "SRL: Shift by Zero"
        );

        check_case(
            2'b00, 32'h80000001, 5'd1,
            32'h40000000,
            "SRL: Logical Right Shift"
        );

        check_case(
            2'b00, 32'h00002000, 5'd13,
            32'h00000001,
            "SRL: Multiple Shift Stages"
        );

        check_case(
            2'b00, 32'h80000000, 5'd31,
            32'h00000001,
            "SRL: Maximum Shift Amount"
        );

        // ========================================
        // 2. SLL - Logical Left Shift
        // ========================================

        check_case(
            2'b01, 32'h12345678, 5'd0,
            32'h12345678,
            "SLL: Shift by Zero"
        );

        check_case(
            2'b01, 32'h80000001, 5'd1,
            32'h00000002,
            "SLL: Logical Left Shift"
        );

        check_case(
            2'b01, 32'h00000001, 5'd13,
            32'h00002000,
            "SLL: Multiple Shift Stages"
        );

        check_case(
            2'b01, 32'h00000001, 5'd31,
            32'h80000000,
            "SLL: Maximum Shift Amount"
        );

        // ========================================
        // 3. SRA - Arithmetic Right Shift
        // ========================================

        check_case(
            2'b10, 32'h7FFFFFFF, 5'd1,
            32'h3FFFFFFF,
            "SRA: Positive Number"
        );

        check_case(
            2'b10, 32'h80000000, 5'd1,
            32'hC0000000,
            "SRA: Negative Number"
        );

        check_case(
            2'b10, 32'hF0000000, 5'd4,
            32'hFF000000,
            "SRA: Sign Extension"
        );

        check_case(
            2'b10, 32'h80000000, 5'd31,
            32'hFFFFFFFF,
            "SRA: Maximum Shift Amount"
        );

        // ========================================
        // 4. Reserved Mode
        // ========================================

        check_case(
            2'b11, 32'h12345678, 5'd4,
            32'h00000000,
            "Reserved Mode"
        );

        // ========================================
        // 5. Test Summary
        // ========================================

        $display("");
        $display("========================================");
        $display("        SHIFTER32 TEST SUMMARY");
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