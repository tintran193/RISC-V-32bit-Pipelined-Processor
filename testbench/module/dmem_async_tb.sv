`timescale 1ns/1ps

module dmem_async_tb;

    // =========================================================
    // Parameters
    // =========================================================
    localparam logic [31:0] START_ADDR = 32'h0000_1000;
    localparam integer      ADDR_WIDTH = 5;

    // ADDR_WIDTH = 5
    // => 2^5 = 32 bytes
    // => 8 words
    localparam integer MEM_WORDS = 2 ** (ADDR_WIDTH - 2);

    // =========================================================
    // DUT signals
    // =========================================================
    logic        i_clk;
    logic [31:0] i_addr;
    logic [31:0] i_wdata;
    logic [3:0]  i_bmsk;
    logic        i_wren;

    logic [31:0] o_rdata;

    // =========================================================
    // Reference memory
    // Used only for verification
    // =========================================================
    logic [31:0] ref_mem [0:MEM_WORDS-1];

    integer i;

    // =========================================================
    // DUT
    // =========================================================
    dmem_async #(
        .START_ADDR(START_ADDR),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .i_clk   (i_clk),
        .i_addr  (i_addr),
        .i_wdata (i_wdata),
        .i_bmsk  (i_bmsk),
        .i_wren  (i_wren),
        .o_rdata (o_rdata)
    );

    // =========================================================
    // Clock
    // =========================================================
    initial begin
        i_clk = 1'b0;

        forever #5 i_clk = ~i_clk;
    end

    // =========================================================
    // Write task
    // =========================================================
    task write_mem;
        input [31:0] addr;
        input [31:0] data;
        input [3:0]  bmsk;

        integer word_index;
        integer offset;

        begin
            i_addr  = addr;
            i_wdata = data;
            i_bmsk  = bmsk;
            i_wren  = 1'b1;

            // Wait for rising edge
            @(posedge i_clk);

            // Allow nonblocking assignments to complete
            #1;

            // Reference model update
            offset = addr - START_ADDR;
            word_index = offset >> 2;

            if ((addr >= START_ADDR) &&
                (addr < START_ADDR + (2 ** ADDR_WIDTH))) begin

                if (bmsk[0])
                    ref_mem[word_index][7:0] = data[7:0];

                if (bmsk[1])
                    ref_mem[word_index][15:8] = data[15:8];

                if (bmsk[2])
                    ref_mem[word_index][23:16] = data[23:16];

                if (bmsk[3])
                    ref_mem[word_index][31:24] = data[31:24];

            end

            i_wren = 1'b0;
            i_bmsk = 4'b0000;
        end

    endtask

    // =========================================================
    // Read check task
    // =========================================================
    task check_read;
        input [31:0] addr;

        integer word_index;
        integer offset;
        reg [31:0] expected;

        begin
            i_addr = addr;

            // Asynchronous read:
            // no clock edge is required
            #1;

            if ((addr >= START_ADDR) &&
                (addr < START_ADDR + (2 ** ADDR_WIDTH))) begin

                offset = addr - START_ADDR;
                word_index = offset >> 2;

                expected = ref_mem[word_index];

            end
            else begin

                expected = 32'b0;
            end

            if (o_rdata !== expected) begin
                $error(
                    "READ FAIL: addr=%h expected=%h actual=%h",
                    addr,
                    expected,
                    o_rdata
                );
            end
            else begin
                $display(
                    "READ PASS: addr=%h data=%h",
                    addr,
                    o_rdata
                );
            end
        end

    endtask

    // =========================================================
    // Main test
    // =========================================================
    initial begin

        $dumpfile("sim/module/dmem_async_tb.vcd");
        $dumpvars(0, dmem_async_tb);

        // -----------------------------------------------------
        // Initialize signals
        // -----------------------------------------------------
        i_addr  = 32'b0;
        i_wdata = 32'b0;
        i_bmsk  = 4'b0000;
        i_wren  = 1'b0;

        for (i = 0; i < MEM_WORDS; i = i + 1)
            ref_mem[i] = 32'b0;

        // Wait a little
        #2;

        // =====================================================
        // TEST 1: Full word write
        // =====================================================

        write_mem(
            START_ADDR,
            32'hAABBCCDD,
            4'b1111
        );

        check_read(START_ADDR);

        // Expected:
        // AABBCCDD
        // =====================================================

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
        // TEST 3: Asynchronous read
        //
        // Change address between clock edges.
        // =====================================================

        i_addr = START_ADDR;
        #1;

        // No clock edge here.
        // o_rdata should immediately reflect mem[1].
        check_read(START_ADDR);

        // =====================================================
        // TEST 4: Read using different byte addresses
        //
        // All four addresses belong to the same word.
        // =====================================================

        check_read(START_ADDR + 0);
        check_read(START_ADDR + 1);
        check_read(START_ADDR + 2);
        check_read(START_ADDR + 3);


        // =====================================================
        // TEST 5: Write byte lane 0
        // =====================================================

        write_mem(
            START_ADDR,
            32'h00000099,
            4'b0001
        );

        // AABBCCDD
        // -> AABBCC99
        check_read(START_ADDR);


        // =====================================================
        // TEST 6: Write byte lane 1
        // =====================================================

        write_mem(
            START_ADDR,
            32'h00008800,
            4'b0010
        );

        // AABBCC99
        // -> AABB8899
        check_read(START_ADDR);


        // =====================================================
        // TEST 7: Write byte lane 2
        // =====================================================

        write_mem(
            START_ADDR,
            32'h00770000,
            4'b0100
        );

        // AABB8899
        // -> AA778899
        check_read(START_ADDR);


        // =====================================================
        // TEST 8: Write byte lane 3
        // =====================================================

        write_mem(
            START_ADDR,
            32'h66000000,
            4'b1000
        );

        // AA778899
        // -> 66778899
        check_read(START_ADDR);


        // =====================================================
        // TEST 9: Write lower two bytes
        // =====================================================

        write_mem(
            START_ADDR + 4,
            32'h0000BBAA,
            4'b0011
        );

        // 11223344
        // -> 1122BBAA
        check_read(START_ADDR + 4);


        // =====================================================
        // TEST 10: Write upper two bytes
        // =====================================================

        write_mem(
            START_ADDR + 4,
            32'hCCDD0000,
            4'b1100
        );

        // 1122BBAA
        // -> CCDDBBAA
        check_read(START_ADDR + 4);


        // =====================================================
        // TEST 11: No byte enabled
        // =====================================================

        write_mem(
            START_ADDR,
            32'hFFFFFFFF,
            4'b0000
        );

        // Data must remain unchanged
        check_read(START_ADDR);


        // =====================================================
        // TEST 12: Out-of-range read
        // =====================================================

        check_read(START_ADDR - 4);
        check_read(START_ADDR + 32);


        // =====================================================
        // TEST 13: Out-of-range write
        // =====================================================

        write_mem(
            START_ADDR + 32,
            32'hDEADBEEF,
            4'b1111
        );

        // Valid memory must not be affected
        check_read(START_ADDR);
        check_read(START_ADDR + 4);

        // =====================================================
        // DONE
        // =====================================================

        $display("");
        $display("==========================================");
        $display("MEMORY ASYNC TEST COMPLETED");
        $display("==========================================");

        $finish;

    end

endmodule