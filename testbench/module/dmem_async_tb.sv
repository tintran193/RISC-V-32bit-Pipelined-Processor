`timescale 1ns/1ps

module dmem_async_tb;

    // Memory parameters
    localparam logic [31:0] START_ADDR = 32'h1000_0000;
    localparam integer ADDR_WIDTH = 10;

    // DUT inputs
    logic        i_clk;
    logic [31:0] i_addr;
    logic [31:0] i_wdata;
    logic [3:0]  i_bmsk;
    logic        i_wren;

    // DUT output
    logic [31:0] o_rdata;

    // Test statistics
    integer pass_count;
    integer fail_count;

    // Instantiate DUT
    dmem_async #(
        .START_ADDR (START_ADDR),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) dut (
        .i_clk   (i_clk),
        .i_addr  (i_addr),
        .i_wdata (i_wdata),
        .i_bmsk  (i_bmsk),
        .i_wren  (i_wren),
        .o_rdata (o_rdata)
    );

    // Clock: period = 10 ns
    initial i_clk = 1'b0;
    always #5 i_clk = ~i_clk;

    // Waveform dump
    initial begin
        $dumpfile("sim/module/dmem_async_tb.vcd");
        $dumpvars(0, dmem_async_tb);
    end

    // -------------------------------------------------
    // Task: Write one word or selected byte lanes
    // -------------------------------------------------
    task automatic write_mem(
        input logic [31:0] addr,
        input logic [31:0] data,
        input logic [3:0]  mask,
        input string       test_name
    );
    begin
        // Drive inputs at the falling edge
        @(negedge i_clk);
        i_addr  = addr;
        i_wdata = data;
        i_bmsk  = mask;
        i_wren  = 1'b1;

        // Wait for synchronous write
        @(posedge i_clk);
        #1;

        // Disable write after the rising edge
        i_wren = 1'b0;
        i_bmsk = 4'b0000;

        $display(
            "[WRITE] %s | addr=%08h data=%08h mask=%b",
            test_name, addr, data, mask
        );
    end
    endtask

    // -------------------------------------------------
    // Task: Check asynchronous read output
    // -------------------------------------------------
    task automatic check_read(
        input logic [31:0] addr,
        input logic [31:0] expected,
        input string       test_name
    );
    begin
        // Change address; no clock edge is needed
        i_addr = addr;
        #1;

        if (o_rdata !== expected) begin
            fail_count = fail_count + 1;

            $display("[FAIL] %s", test_name);
            $display("       Address  = 0x%08h", addr);
            $display("       Expected = 0x%08h", expected);
            $display("       Actual   = 0x%08h", o_rdata);
        end
        else begin
            pass_count = pass_count + 1;

            $display(
                "[PASS] %s | addr=%08h rdata=%08h",
                test_name, addr, o_rdata
            );
        end
    end
    endtask

    // -------------------------------------------------
    // Test sequence
    // -------------------------------------------------
    initial begin
        i_addr     = START_ADDR;
        i_wdata    = 32'b0;
        i_bmsk     = 4'b0;
        i_wren     = 1'b0;
        pass_count = 0;
        fail_count = 0;

        // Allow signals to settle
        #1;

        // =============================================
        // TC1: Write full word
        // Expected: 0x12345678
        // =============================================
        write_mem(
            START_ADDR,
            32'h12345678,
            4'b1111,
            "TC1: Write Full Word"
        );

        check_read(
            START_ADDR,
            32'h12345678,
            "TC1: Read Back Full Word"
        );

        // =============================================
        // TC2: Write byte lane 0
        // Old: 0x12345678
        // New: 0x123456DD
        // =============================================
        write_mem(
            START_ADDR,
            32'hAABBCCDD,
            4'b0001,
            "TC2: Write Byte Lane 0"
        );

        check_read(
            START_ADDR,
            32'h123456DD,
            "TC2: Verify Byte Lane 0"
        );

        // =============================================
        // TC3: Write byte lane 2
        // Old: 0x123456DD
        // New: 0x12BB56DD
        // =============================================
        write_mem(
            START_ADDR,
            32'hAABBCCDD,
            4'b0100,
            "TC3: Write Byte Lane 2"
        );

        check_read(
            START_ADDR,
            32'h12BB56DD,
            "TC3: Verify Byte Lane 2"
        );

        // =============================================
        // TC4: Write lower two byte lanes
        // Old: 0x12BB56DD
        // New: 0x12BB3344
        // =============================================
        write_mem(
            START_ADDR,
            32'h11223344,
            4'b0011,
            "TC4: Write Lower Two Byte Lanes"
        );

        check_read(
            START_ADDR,
            32'h12BB3344,
            "TC4: Verify Lower Two Byte Lanes"
        );

        // =============================================
        // TC5: Write upper two byte lanes
        // Old: 0x12BB3344
        // New: 0x44333344
        // =============================================
        write_mem(
            START_ADDR,
            32'h44332211,
            4'b1100,
            "TC5: Write Upper Two Byte Lanes"
        );

        check_read(
            START_ADDR,
            32'h44333344,
            "TC5: Verify Upper Two Byte Lanes"
        );

        // =============================================
        // TC6: Write another word
        // Address = START_ADDR + 4
        // Expected: 0x12345678
        // =============================================
        write_mem(
            START_ADDR + 32'd4,
            32'h12345678,
            4'b1111,
            "TC6: Write Another Word"
        );

        check_read(
            START_ADDR + 32'd4,
            32'h12345678,
            "TC6: Read Another Word"
        );

        // =============================================
        // TC7: Out-of-range read
        // Memory size = 1024 bytes
        // START_ADDR + 0x1000 is outside the region
        // =============================================
        check_read(
            START_ADDR + 32'h1000,
            32'h00000000,
            "TC7: Out-of-Range Read"
        );

        // =============================================
        // TC8: Asynchronous read
        // Change address between clock edges
        // =============================================
        @(negedge i_clk);

        i_wren = 1'b0;

        // Read first word
        check_read(
            START_ADDR,
            32'h44333344,
            "TC8: Async Read First Word"
        );

        // Change address before the next rising edge
        check_read(
            START_ADDR + 32'd4,
            32'h12345678,
            "TC8: Async Read Second Word Without Clock"
        );

        // =============================================
        // Summary
        // =============================================
        $display("");
        $display("========================================");
        $display("       DMEM ASYNC TEST SUMMARY");
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