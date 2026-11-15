
`timescale 1ns/1ps

module timer_tb;

    // ============================================================
    // 1. Testbench signals
    // ============================================================

    logic        i_clk;
    logic        i_rstn;

    logic [11:0] i_addr;
    logic [31:0] i_wdata;
    logic [3:0]  i_bmsk;
    logic        i_wren;

    logic [31:0] o_rdata;

    integer pass_count;
    integer fail_count;


    // ============================================================
    // 2. Instantiate DUT
    // ============================================================

    timer dut (
        .i_clk   (i_clk),
        .i_rstn  (i_rstn),

        .i_addr  (i_addr),
        .i_wdata (i_wdata),
        .i_bmsk  (i_bmsk),
        .i_wren  (i_wren),

        .o_rdata (o_rdata)
    );


    // ============================================================
    // 3. Clock generation
    // Period = 10 ns
    // ============================================================

    initial begin
        i_clk = 1'b0;
        forever #5 i_clk = ~i_clk;
    end


    // ============================================================
    // 4. Bus write task
    // ============================================================

    task automatic bus_write (
        input logic [11:0] addr,
        input logic [31:0] data,
        input logic [3:0]  mask
    );

        begin
            // Drive signals at falling edge
            @(negedge i_clk);

            i_addr  = addr;
            i_wdata = data;
            i_bmsk  = mask;
            i_wren  = 1'b1;

            // Write occurs at rising edge
            @(posedge i_clk);
            #1;

            // Deassert write enable
            i_wren  = 1'b0;
            i_wdata = 32'b0;
            i_bmsk  = 4'b0000;
        end

    endtask


    // ============================================================
    // 5. Read check task
    // ============================================================

    task automatic check_read (
        input logic [11:0] addr,
        input logic [31:0] expected,
        input string test_name
    );

        logic [31:0] actual;

        begin
            // Read is asynchronous
            i_addr = addr;
            #1;

            actual = o_rdata;

            if (actual === expected) begin
                $display(
                    "[PASS] %-30s Addr=%h Data=%h",
                    test_name, addr, actual
                );

                pass_count = pass_count + 1;
            end
            else begin
                $display(
                    "[FAIL] %-30s Addr=%h Expected=%h Actual=%h",
                    test_name, addr, expected, actual
                );

                fail_count = fail_count + 1;
            end
        end

    endtask


    // ============================================================
    // 6. Internal counter check task
    // Used for testing 64-bit carry and overflow.
    // ============================================================

    task automatic check_count64 (
        input logic [63:0] expected,
        input string test_name
    );

        logic [63:0] actual;

        begin
            #1;
            actual = dut.timer_count;

            if (actual === expected) begin
                $display(
                    "[PASS] %-30s COUNT=%h",
                    test_name, actual
                );

                pass_count = pass_count + 1;
            end
            else begin
                $display(
                    "[FAIL] %-30s Expected=%h Actual=%h",
                    test_name, expected, actual
                );

                fail_count = fail_count + 1;
            end
        end

    endtask


    // ============================================================
    // 7. Main test sequence
    // ============================================================

    initial begin

        $dumpfile("sim/devices/timer_tb.vcd");
        $dumpvars(0, timer_tb);

        // Initialize signals
        i_rstn  = 1'b1;
        i_addr  = 12'b0;
        i_wdata = 32'b0;
        i_bmsk  = 4'b0;
        i_wren  = 1'b0;

        pass_count = 0;
        fail_count = 0;


        // ========================================================
        // TEST 1: Reset
        // ========================================================

        $display("\n========================================");
        $display("TEST 1: RESET");
        $display("========================================");

        #1;
        i_rstn = 1'b0;

        repeat (2) @(negedge i_clk);

        i_rstn = 1'b1;

        @(posedge i_clk);
        #1;

        check_read(12'h000, 32'h00000000, "CTRL reset");
        check_read(12'h004, 32'h00000000, "COUNT_LO reset");
        check_read(12'h008, 32'h00000000, "COUNT_HI reset");


        // ========================================================
        // TEST 2: Reserved bits in CTRL
        // ========================================================

        $display("\n========================================");
        $display("TEST 2: RESERVED BITS");
        $display("========================================");

        // Bits [31:2] = 1
        // EN = 0, CLR = 0
        bus_write(
            12'h000,
            32'hFFFFFFFC,
            4'b1111
        );

        check_read(
            12'h000,
            32'h00000000,
            "CTRL reserved bits ignored"
        );


        // ========================================================
        // TEST 3: Incorrect byte lane
        // ========================================================

        $display("\n========================================");
        $display("TEST 3: BYTE MASK");
        $display("========================================");

        // EN is in byte lane 0.
        // Writing through byte lane 1 must be ignored.

        bus_write(
            12'h000,
            32'h00000001,
            4'b0010
        );

        check_read(
            12'h000,
            32'h00000000,
            "CTRL wrong byte lane"
        );


        // ========================================================
        // TEST 4: Enable timer
        // ========================================================

        $display("\n========================================");
        $display("TEST 4: ENABLE TIMER");
        $display("========================================");

        bus_write(
            12'h000,
            32'h00000001,
            4'b0001
        );

        check_read(
            12'h000,
            32'h00000001,
            "CTRL EN = 1"
        );

        // Wait for 3 counter clock edges.
        repeat (3) begin
            @(posedge i_clk);
            #1;
        end

        check_read(
            12'h004,
            32'h00000003,
            "COUNT_LO after 3 cycles"
        );

        check_read(
            12'h008,
            32'h00000000,
            "COUNT_HI after 3 cycles"
        );


        // ========================================================
        // TEST 5: CLR priority over EN
        // ========================================================

        $display("\n========================================");
        $display("TEST 5: CLEAR PRIORITY");
        $display("========================================");

        // EN = 1 and CLR = 1.
        // CLR must clear the counter.

        bus_write(
            12'h000,
            32'h00000003,
            4'b0001
        );

        check_read(
            12'h000,
            32'h00000001,
            "CTRL after CLR command"
        );

        check_read(
            12'h004,
            32'h00000000,
            "COUNT_LO cleared"
        );

        check_read(
            12'h008,
            32'h00000000,
            "COUNT_HI cleared"
        );

        // EN remains enabled.
        // Counter starts counting again at next clock edge.

        @(posedge i_clk);
        #1;

        check_count64(
            64'h00000000_00000001,
            "Count after CLR"
        );


        // ========================================================
        // TEST 6: Disable timer and hold
        // ========================================================

        $display("\n========================================");
        $display("TEST 6: DISABLE AND HOLD");
        $display("========================================");

        bus_write(
            12'h000,
            32'h00000000,
            4'b0001
        );

        check_read(
            12'h000,
            32'h00000000,
            "CTRL EN = 0"
        );

        // In this synchronous implementation, the old EN=1
        // applies at the edge that writes EN=0.
        // Therefore the counter has advanced from 1 to 2.

        check_read(
            12'h004,
            32'h00000002,
            "COUNT after disable"
        );

        repeat (3) begin
            @(posedge i_clk);
            #1;
        end

        check_count64(
            64'h00000000_00000002,
            "Counter holds while disabled"
        );


        // ========================================================
        // TEST 7: COUNT_LO and COUNT_HI are read-only
        // ========================================================

        $display("\n========================================");
        $display("TEST 7: READ ONLY REGISTERS");
        $display("========================================");

        bus_write(
            12'h004,
            32'hFFFFFFFF,
            4'b1111
        );

        bus_write(
            12'h008,
            32'hFFFFFFFF,
            4'b1111
        );

        check_read(
            12'h004,
            32'h00000002,
            "COUNT_LO write ignored"
        );

        check_read(
            12'h008,
            32'h00000000,
            "COUNT_HI write ignored"
        );


        // ========================================================
        // TEST 8: Clear while disabled
        // ========================================================

        $display("\n========================================");
        $display("TEST 8: CLEAR WHILE DISABLED");
        $display("========================================");

        bus_write(
            12'h000,
            32'h00000002,
            4'b0001
        );

        check_read(
            12'h000,
            32'h00000000,
            "CLR reads as zero, EN=0"
        );

        check_count64(
            64'h00000000_00000000,
            "Clear while disabled"
        );


        // ========================================================
        // TEST 9: Read COUNT_LO and COUNT_HI
        // ========================================================

        $display("\n========================================");
        $display("TEST 9: READ 64-BIT COUNTER");
        $display("========================================");

        // Directly preload the internal counter for simulation.
        // Timer is disabled, so the value will remain unchanged.

        @(negedge i_clk);

        dut.timer_count = 64'h12345678_9ABCDEF0;

        check_read(
            12'h004,
            32'h9ABCDEF0,
            "Read COUNT_LO"
        );

        check_read(
            12'h008,
            32'h12345678,
            "Read COUNT_HI"
        );


        // ========================================================
        // TEST 10: Carry from LOW to HIGH
        // ========================================================

        $display("\n========================================");
        $display("TEST 10: CARRY LOW TO HIGH");
        $display("========================================");

        // Set COUNT_LO = FFFFFFFF.
        // COUNT_HI = 00000000.

        @(negedge i_clk);

        dut.timer_count = 64'h00000000_FFFFFFFF;

        // Enable timer.
        bus_write(
            12'h000,
            32'h00000001,
            4'b0001
        );

        // At the write edge, old EN was 0.
        // At the next edge, the 64-bit incrementer operates.

        @(posedge i_clk);
        #1;

        check_count64(
            64'h00000001_00000000,
            "Carry LOW to HIGH"
        );


        // Stop timer.
        bus_write(
            12'h000,
            32'h00000000,
            4'b0001
        );


        // ========================================================
        // TEST 11: 64-bit overflow
        // ========================================================

        $display("\n========================================");
        $display("TEST 11: 64-BIT OVERFLOW");
        $display("========================================");

        @(negedge i_clk);

        dut.timer_count = 64'hFFFFFFFF_FFFFFFFF;

        // Enable timer.
        bus_write(
            12'h000,
            32'h00000001,
            4'b0001
        );

        // Wait for one counting edge.
        @(posedge i_clk);
        #1;

        // FFFFFFFFFFFFFFFF + 1 wraps around to zero.

        check_count64(
            64'h00000000_00000000,
            "64-bit counter overflow"
        );


        // ========================================================
        // TEST 12: Unmapped address
        // ========================================================

        $display("\n========================================");
        $display("TEST 12: UNMAPPED ADDRESS");
        $display("========================================");

        // Stop timer.
        bus_write(
            12'h000,
            32'h00000000,
            4'b0001
        );

        @(negedge i_clk);

        dut.timer_count = 64'h00000000_12345678;

        // Read reserved offset.
        check_read(
            12'h00C,
            32'h00000000,
            "Unmapped address read"
        );

        // Write reserved offset.
        bus_write(
            12'h00C,
            32'hFFFFFFFF,
            4'b1111
        );

        check_count64(
            64'h00000000_12345678,
            "Unmapped address write ignored"
        );


        // ========================================================
        // TEST SUMMARY
        // ========================================================

        $display("\n========================================");
        $display("TIMER TEST SUMMARY");
        $display("========================================");

        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);

        if (fail_count == 0) begin
            $display("\nALL TIMER TESTS PASSED!");
        end
        else begin
            $display("\nTIMER TEST FAILED!");
            $fatal(1, "There are %0d failed tests.", fail_count);
        end

        $finish;

    end

endmodule
