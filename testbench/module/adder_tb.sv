`timescale 1ns/1ps

module adder_tb;

    // Testbench signals
    logic        cin;
    logic [31:0] operand_a;
    logic [31:0] operand_b;

    logic [31:0] sum;
    logic        cout;

    // Instantiate DUT (Device Under Test)
    adder dut (
        .cin      (cin),
        .operand_a(operand_a),
        .operand_b(operand_b),
        .sum      (sum),
        .cout     (cout)
    );

    // Waveform dump
    initial begin
        $dumpfile("sim/module/adder_tb.vcd");
        $dumpvars(0, adder_tb);
    end

    // Test cases
    initial begin
        // Initialize
        cin      = 0;
        operand_a = 0;
        operand_b = 0;

        #10;

        // Test 1: 0 + 0 + 0
        operand_a = 32'h00000000;
        operand_b = 32'h00000000;
        cin       = 1'b0;

        #10;
        $display("Test 1: A=%h B=%h Cin=%b -> Sum=%h Cout=%b",
                 operand_a, operand_b, cin, sum, cout);

        // Test 2: 1 + 2 + 0 = 3
        operand_a = 32'h00000001;
        operand_b = 32'h00000002;
        cin       = 1'b0;

        #10;
        $display("Test 2: A=%h B=%h Cin=%b -> Sum=%h Cout=%b",
                 operand_a, operand_b, cin, sum, cout);

        // Test 3: 0xFFFFFFFF + 1 = 0x00000000, Cout = 1
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'h00000001;
        cin       = 1'b0;

        #10;
        $display("Test 3: A=%h B=%h Cin=%b -> Sum=%h Cout=%b",
                 operand_a, operand_b, cin, sum, cout);

        // Test 4: 0xFFFFFFFF + 0 + 1
        operand_a = 32'hFFFFFFFF;
        operand_b = 32'h00000000;
        cin       = 1'b1;

        #10;
        $display("Test 4: A=%h B=%h Cin=%b -> Sum=%h Cout=%b",
                 operand_a, operand_b, cin, sum, cout);

        // Test 5: 0x7FFFFFFF + 1
        operand_a = 32'h7FFFFFFF;
        operand_b = 32'h00000001;
        cin       = 1'b0;

        #10;
        $display("Test 5: A=%h B=%h Cin=%b -> Sum=%h Cout=%b",
                 operand_a, operand_b, cin, sum, cout);

        // Test 6: 0x12345678 + 0x87654321
        operand_a = 32'h12345678;
        operand_b = 32'h87654321;
        cin       = 1'b0;

        #10;
        $display("Test 6: A=%h B=%h Cin=%b -> Sum=%h Cout=%b",
                 operand_a, operand_b, cin, sum, cout);

        #10;

        $display("========================================");
        $display("All tests completed.");
        $display("========================================");

        $finish;
    end

endmodule
