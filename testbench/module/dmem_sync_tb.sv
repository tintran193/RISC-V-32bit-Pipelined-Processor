`timescale 1ns/1ps

module dmem_sync_tb;

    // =========================================================
    // Parameters
    // =========================================================
    localparam logic [31:0] START_ADDR = 32'h8000_0000;
    localparam integer      ADDR_WIDTH = 5;

    // 32 bytes = 8 words
    localparam integer MEM_WORDS = 2 ** (ADDR_WIDTH - 2);

    // =========================================================
    // DUT signals
    // =========================================================
    logic        i_clk;
    logic [31:0] i_addr;
    logic [31:0] i_wdata;
    logic [3:0]  i_bmsk;
    logic        i_rden;
    logic        i_wren;

    logic [31:0] o_rdata;

    // =========================================================
    // Reference memory
    // =========================================================
    logic [31:0] ref_mem [0:MEM_WORDS-1];

    integer i;
    integer errors;

    integer random_word;
    integer offset;
    integer word_index;

    logic [31:0] random_addr;
    logic [31:0] random_data;
    logic [3:0]  random_bmsk;

    logic [31:0] previous_data;
    logic [31:0] expected_data;

    // =========================================================
    // DUT
    // =========================================================
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

    // =========================================================
    // Clock: 10 ns period
    // =========================================================
    initial begin
        i_clk = 1'b0;
        forever #5 i_clk = ~i_clk;
    end

    // =========================================================
    // Task: update reference memory
    //
    // Call only for valid addresses.
    // =========================================================
    task update_reference;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  bmsk;

        integer ref_offset;
        integer ref_index;

        begin
            ref_offset = addr - START_ADDR;
            ref_index  = ref_offset >> 2;

            if (bmsk[0])
                ref_mem[ref_index][7:0] = data[7:0];

            if (bmsk[1])
                ref_mem[ref_index][15:8] = data[15:8];

            if (bmsk[2])
                ref_mem[ref_index][23:16] = data[23:16];

            if (bmsk[3])
                ref_mem[ref_index][31:24] = data[31:24];
        end
    endtask

    // =========================================================
    // Task: synchronous write
    //
    // Drive at falling edge.
    // Memory updates at rising edge.
    // =========================================================
    task write_mem;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  bmsk;

        begin
            @(negedge i_clk);

            i_addr  = addr;
            i_wdata = data;
            i_bmsk  = bmsk;
            i_wren  = 1'b1;
            i_rden  = 1'b0;

            @(posedge i_clk);
            #1;

            // Update reference model only for valid addresses.
            if ((addr >= START_ADDR) &&
                (addr < START_ADDR + (2 ** ADDR_WIDTH))) begin

                update_reference(addr, data, bmsk);

            end

            i_wren = 1'b0;
            i_bmsk = 4'b0000;
        end
    endtask

    // =========================================================
    // Task: synchronous read and check
    //
    // A valid read is sampled at posedge i_clk.
    // =========================================================
    task check_read;
        input [31:0] addr;

        reg [31:0] expected;

        integer read_offset;
        integer read_index;

        begin
            @(negedge i_clk);

            i_addr = addr;
            i_rden = 1'b1;
            i_wren = 1'b0;

            // The output must not update merely because the
            // address changes; synchronous read waits for clk.
            @(posedge i_clk);
            #1;

            if ((addr >= START_ADDR) &&
                (addr < START_ADDR + (2 ** ADDR_WIDTH))) begin

                read_offset = addr - START_ADDR;
                read_index  = read_offset >> 2;

                expected = ref_mem[read_index];

            end
            else begin
                expected = 32'b0;
            end

            if (o_rdata !== expected) begin
                $display(
                    "READ FAIL: addr=%h expected=%h actual=%h",
                    addr, expected, o_rdata
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "READ PASS: addr=%h data=%h",
                    addr, o_rdata
                );
            end

            i_rden = 1'b0;
        end
    endtask

    // =========================================================
    // Main test
    // =========================================================
    initial begin

        $dumpfile("sim/module/dmem_sync_tb.vcd");
        $dumpvars(0, dmem_sync_tb);

        errors = 0;

        // Initialize DUT inputs
        i_addr  = 32'b0;
        i_wdata = 32'b0;
        i_bmsk  = 4'b0000;
        i_rden  = 1'b0;
        i_wren  = 1'b0;

        // Initialize reference model.
        // The DUT memory itself is not reset by this exercise.
        for (i = 0; i < MEM_WORDS; i = i + 1)
            ref_mem[i] = 32'b0;

        #2;

        // =====================================================
        // TEST 0: Initialize all words
        //
        // Avoid reading uninitialized DUT memory (X values).
        // =====================================================
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            write_mem(
                START_ADDR + (i * 4),
                32'hC0000000 | i,
                4'b1111
            );
        end

        $display("PASS TEST 0: Initialize all memory words");

        // =====================================================
        // TEST 1: Full-word write
        // =====================================================
        write_mem(
            START_ADDR,
            32'hAABBCCDD,
            4'b1111
        );

        check_read(START_ADDR);

        // =====================================================
        // TEST 2: Write second word
        // =====================================================
        write_mem(
            START_ADDR + 4,
            32'h11223344,
            4'b1111
        );

        check_read(START_ADDR + 4);

        // =====================================================
        // TEST 3: Verify synchronous-read timing
        //
        // Previously read word 1 = 11223344.
        // Change address to word 0 between clock edges.
        // Output must remain unchanged until next posedge.
        // =====================================================
        @(negedge i_clk);

        previous_data = o_rdata;

        i_addr = START_ADDR;
        i_rden = 1'b1;
        i_wren = 1'b0;

        #1;

        if (o_rdata !== previous_data) begin
            $display(
                "SYNC TIMING FAIL: output changed before clock, "
                "previous=%h actual=%h",
                previous_data, o_rdata
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS TEST 3A: Output holds before rising edge");
        end

        @(posedge i_clk);
        #1;

        if (o_rdata !== 32'hAABBCCDD) begin
            $display(
                "SYNC READ FAIL: expected=AABBCCDD actual=%h",
                o_rdata
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS TEST 3B: Output updates at rising edge");
        end

        i_rden = 1'b0;

        // =====================================================
        // TEST 4: Read from different byte addresses
        //
        // All four byte addresses in one word return the
        // complete 32-bit word in this memory interface.
        // =====================================================
        check_read(START_ADDR);
        check_read(START_ADDR + 1);
        check_read(START_ADDR + 2);
        check_read(START_ADDR + 3);

        // =====================================================
        // TEST 5: Write byte lane 0
        //
        // AABBCCDD -> AABBCC99
        // =====================================================
        write_mem(
            START_ADDR,
            32'h00000099,
            4'b0001
        );

        check_read(START_ADDR);

        // =====================================================
        // TEST 6: Write byte lane 1
        //
        // AABBCC99 -> AABB8899
        // =====================================================
        write_mem(
            START_ADDR,
            32'h00008800,
            4'b0010
        );

        check_read(START_ADDR);

        // =====================================================
        // TEST 7: Write byte lane 2
        //
        // AABB8899 -> AA778899
        // =====================================================
        write_mem(
            START_ADDR,
            32'h00770000,
            4'b0100
        );

        check_read(START_ADDR);

        // =====================================================
        // TEST 8: Write byte lane 3
        //
        // AA778899 -> 66778899
        // =====================================================
        write_mem(
            START_ADDR,
            32'h66000000,
            4'b1000
        );

        check_read(START_ADDR);

        // =====================================================
        // TEST 9: Write lower two byte lanes
        //
        // 11223344 -> 1122BBAA
        // =====================================================
        write_mem(
            START_ADDR + 4,
            32'h0000BBAA,
            4'b0011
        );

        check_read(START_ADDR + 4);

        // =====================================================
        // TEST 10: Write upper two byte lanes
        //
        // 1122BBAA -> CCDDBBAA
        // =====================================================
        write_mem(
            START_ADDR + 4,
            32'hCCDD0000,
            4'b1100
        );

        check_read(START_ADDR + 4);

        // =====================================================
        // TEST 11: No byte lane enabled
        //
        // Data must remain unchanged.
        // =====================================================
        write_mem(
            START_ADDR,
            32'hFFFFFFFF,
            4'b0000
        );

        check_read(START_ADDR);

        // =====================================================
        // TEST 12: i_rden = 0 must hold output
        // =====================================================
        @(negedge i_clk);

        previous_data = o_rdata;

        i_addr = START_ADDR + 4;
        i_rden = 1'b0;
        i_wren = 1'b0;

        @(posedge i_clk);
        #1;

        if (o_rdata !== previous_data) begin
            $display(
                "READ HOLD FAIL: expected=%h actual=%h",
                previous_data, o_rdata
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS TEST 12: Output held when i_rden=0");
        end

        // =====================================================
        // TEST 13: Out-of-range reads
        //
        // Output becomes zero at the next rising edge,
        // not immediately when the address changes.
        // =====================================================
        check_read(START_ADDR - 4);
        check_read(START_ADDR + 32);

        // =====================================================
        // TEST 14: Out-of-range write must be ignored
        // =====================================================
        write_mem(
            START_ADDR + 32,
            32'hDEADBEEF,
            4'b1111
        );

        check_read(START_ADDR);
        check_read(START_ADDR + 4);

        // =====================================================
        // TEST 15: Random write/read tests
        // =====================================================
        for (i = 0; i < 1000; i = i + 1) begin

            random_word = $urandom_range(0, MEM_WORDS - 1);
            random_addr = START_ADDR + (random_word * 4);
            random_data = $urandom;
            random_bmsk = $urandom_range(0, 15);

            write_mem(
                random_addr,
                random_data,
                random_bmsk
            );

            check_read(random_addr);

        end

        // =====================================================
        // Summary
        // =====================================================
        $display("");
        $display("==========================================");

        if (errors == 0) begin
            $display("DMEM SYNC TEST PASSED");
        end
        else begin
            $display("DMEM SYNC TEST FAILED: %0d error(s)", errors);
            $fatal(1, "Dmem sync verification failed");
        end

        $display("==========================================");

        $finish;

    end

endmodule