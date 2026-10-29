`timescale 1ns/1ps

module dmem_sync_tb;

    localparam logic [31:0] START_ADDR = 32'h1000_0000;
    localparam integer ADDR_WIDTH = 10;

    // DUT inputs
    logic        i_clk;
    logic [31:0] i_addr;
    logic [31:0] i_wdata;
    logic [3:0]  i_bmsk;
    logic        i_rden;
    logic        i_wren;

    // DUT output
    logic [31:0] o_rdata;

    integer pass_count;
    integer fail_count;

    // =========================================
    // DUT
    // =========================================
    dmem_sync #(
        .START_ADDR (START_ADDR),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
        .i_clk   (i_clk),
        .i_addr  (i_addr),
        .i_wdata (i_wdata),
        .i_bmsk  (i_bmsk),
        .i_rden  (i_rden),
        .i_wren  (i_wren),
        .o_rdata (o_rdata)
    );

    // Clock period = 10 ns
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    // Waveform
    initial begin
        $dumpfile("sim/module/dmem_sync_tb.vcd");
        $dumpvars(0, dmem_sync_tb);
    end

    // =========================================
    // Check output
    // =========================================
    task automatic check_value(
        input logic [31:0] expected,
        input string test_name
    );
    begin
        if (o_rdata !== expected) begin
            fail_count = fail_count + 1;

            $display("[FAIL] %s", test_name);
            $display("       Expected = 0x%08h", expected);
            $display("       Actual   = 0x%08h", o_rdata);
        end
        else begin
            pass_count = pass_count + 1;

            $display("[PASS] %s | o_rdata = 0x%08h",
                     test_name, o_rdata);
        end
    end
    endtask

    // =========================================
    // Synchronous write
    // =========================================
    task automatic write_mem(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [3:0] mask,
        input string test_name
    );
    begin
        @(negedge i_clk);

        i_addr  = addr;
        i_wdata = data;
        i_bmsk  = mask;
        i_wren  = 1'b1;
        i_rden  = 1'b0;

        // Write takes effect at the rising edge
        @(posedge i_clk);
        #1;

        $display("[WRITE] %s | addr=%08h data=%08h mask=%b",
                 test_name, addr, data, mask);

        i_wren = 1'b0;
        i_bmsk = 4'b0000;
    end
    endtask

    // =========================================
    // Synchronous read
    // =========================================
    task automatic read_mem(
        input logic [31:0] addr,
        input logic [31:0] expected,
        input string test_name
    );
    begin
        @(negedge i_clk);

        i_addr = addr;
        i_rden = 1'b1;
        i_wren = 1'b0;
        i_bmsk = 4'b0000;

        // Read output updates at the rising edge
        @(posedge i_clk);
        #1;

        check_value(expected, test_name);

        i_rden = 1'b0;
    end
    endtask

    // =========================================
    // Test sequence
    // =========================================
    initial begin
        i_addr     = START_ADDR;
        i_wdata    = 32'b0;
        i_bmsk     = 4'b0000;
        i_rden     = 1'b0;
        i_wren     = 1'b0;

        pass_count = 0;
        fail_count = 0;

        #1;

        // -------------------------------------
        // TC1: Write full word
        // Expected: 0x12345678
        // -------------------------------------
        write_mem(
            START_ADDR,
            32'h12345678,
            4'b1111,
            "TC1: Write Full Word"
        );

        read_mem(
            START_ADDR,
            32'h12345678,
            "TC1: Read Back Full Word"
        );

        // -------------------------------------
        // TC2: Write byte lane 0
        // 12345678 -> 123456DD
        // -------------------------------------
        write_mem(
            START_ADDR,
            32'hAABBCCDD,
            4'b0001,
            "TC2: Write Byte Lane 0"
        );

        read_mem(
            START_ADDR,
            32'h123456DD,
            "TC2: Verify Byte Lane 0"
        );

        // -------------------------------------
        // TC3: Write byte lane 2
        // 123456DD -> 12BB56DD
        // -------------------------------------
        write_mem(
            START_ADDR,
            32'hAABBCCDD,
            4'b0100,
            "TC3: Write Byte Lane 2"
        );

        read_mem(
            START_ADDR,
            32'h12BB56DD,
            "TC3: Verify Byte Lane 2"
        );

        // -------------------------------------
        // TC4: Write lower two byte lanes
        // 12BB56DD -> 12BB3344
        // -------------------------------------
        write_mem(
            START_ADDR,
            32'h11223344,
            4'b0011,
            "TC4: Write Lower Two Byte Lanes"
        );

        read_mem(
            START_ADDR,
            32'h12BB3344,
            "TC4: Verify Lower Two Byte Lanes"
        );

        // -------------------------------------
        // TC5: Write upper two byte lanes
        // 12BB3344 -> 44333344
        // -------------------------------------
        write_mem(
            START_ADDR,
            32'h44332211,
            4'b1100,
            "TC5: Write Upper Two Byte Lanes"
        );

        read_mem(
            START_ADDR,
            32'h44333344,
            "TC5: Verify Upper Two Byte Lanes"
        );

        // -------------------------------------
        // TC6: Write another word
        // -------------------------------------
        write_mem(
            START_ADDR + 32'd4,
            32'h12345678,
            4'b1111,
            "TC6: Write Another Word"
        );

        read_mem(
            START_ADDR + 32'd4,
            32'h12345678,
            "TC6: Read Another Word"
        );

        // -------------------------------------
        // TC7: Read out of range
        // -------------------------------------
        read_mem(
            START_ADDR + 32'h1000,
            32'h00000000,
            "TC7: Read Out of Range"
        );

        // -------------------------------------
        // TC8: Synchronous Read
        // Keep i_rden = 1.
        // Change address between rising edges.
        // -------------------------------------

        // First address: read word 0
        @(negedge i_clk);

        i_addr = START_ADDR;
        i_rden = 1'b1;
        i_wren = 1'b0;
        i_bmsk = 4'b0000;

        @(posedge i_clk);
        #1;

        check_value(
            32'h44333344,
            "TC8a: Read First Word At Rising Edge"
        );

        // Change address after the rising edge.
        // Keep i_rden = 1.
        i_addr = START_ADDR + 32'd4;

        #1;

        // Output must still hold the value from word 0.
        check_value(
            32'h44333344,
            "TC8b: Output Unchanged Before Next Rising Edge"
        );

        // At the next rising edge, word 1 is sampled.
        @(posedge i_clk);
        #1;

        check_value(
            32'h12345678,
            "TC8c: Output Updates At Next Rising Edge"
        );

        i_rden = 1'b0;

        // -------------------------------------
        // TC9: Simultaneous Read and Write
        // Read-before-write
        //
        // Old word = 0x44333344
        // Write data = 0x12345678
        //
        // Expected o_rdata = OLD word
        // Memory after edge = NEW word
        // -------------------------------------
        @(negedge i_clk);

        i_addr  = START_ADDR;
        i_wdata = 32'h12345678;
        i_bmsk  = 4'b1111;
        i_wren  = 1'b1;
        i_rden  = 1'b1;

        @(posedge i_clk);
        #1;

        check_value(
            32'h44333344,
            "TC9: Simultaneous Read/Write - Read Before Write"
        );

        // Disable both operations
        i_wren = 1'b0;
        i_rden = 1'b0;
        i_bmsk = 4'b0000;

        // Read again to verify that the write succeeded.
        read_mem(
            START_ADDR,
            32'h12345678,
            "TC9: Verify New Word After Simultaneous Write"
        );

        // -------------------------------------
        // Summary
        // -------------------------------------
        $display("");
        $display("========================================");
        $display("          DMEM SYNC TEST SUMMARY");
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