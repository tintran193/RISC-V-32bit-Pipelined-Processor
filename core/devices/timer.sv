module timer (
    input  logic i_clk,
    input  logic i_rstn,
    input  logic [11:0] i_addr,
    input  logic [31:0] i_wdata,
    input  logic [3:0]  i_bmsk,
    input  logic        i_wren,

    output logic [31:0] o_rdata
);

    // CTRL register:
    // bit [0] = EN
    // bit [1] = CLR (write-one command, not stored)
    logic timer_en;

    // 64-bit counter
    logic [63:0] timer_count;
    // Next counter value
    logic [63:0] timer_count_next;

    // Carry from lower 32-bit adder
    logic carry_low;

    // Control signals
    logic ctrl_sel;
    logic ctrl_write;
    logic clear_cmd;

    // Unused carry from upper adder
    logic carry_high_unused;

    // CTRL:     offset 0x000
    // COUNT_LO: offset 0x004
    // COUNT_HI: offset 0x008

    assign ctrl_sel = (i_addr[11:2] == 10'h000);

    // Only byte lane 0 contains valid CTRL bits.
    assign ctrl_write = i_wren & ctrl_sel & i_bmsk[0];

    // CLR is a write-one command.
    // It is active only during a valid write to CTRL.
    assign clear_cmd = ctrl_write & i_wdata[1];


    // 64-bit incrementer using two 32-bit adders

    // Low adder: timer_count[31:0] + 1
    adder32 u_timer_adder_low (
        .i_a (timer_count[31:0]),
        .i_b (32'd1),
        .i_sub (1'b0),
        .o_sum (timer_count_next[31:0]),
        .o_cout (carry_low)
    );

    // High adder: timer_count[63:32] + carry_low
    adder32 u_timer_adder_high (
        .i_a (timer_count[63:32]),
        .i_b ({31'b0, carry_low}),
        .i_sub (1'b0),
        .o_sum (timer_count_next[63:32]),
        .o_cout (carry_high_unused)
    );


    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            // Reset timer: disable counting and clear counter
            timer_en    <= 1'b0;
            timer_count <= 64'b0;
        end else begin

            if (ctrl_write) begin
                timer_en <= i_wdata[0];
            end
            if (clear_cmd) begin
                // Writing 1 to CLR clears the entire counter.
                timer_count <= 64'b0;
            end
            else if (timer_en) begin
                // EN = 1: increment counter by one.
                timer_count <= timer_count_next;
            end
            // EN = 0: hold current counter value.
        end
    end

    // Read operation
    always_comb begin
        // Default: unmapped address returns zero.
        o_rdata = 32'b0;

        case (i_addr[11:2])

            // ----------------------------------------------------
            // CTRL: offset 0x000
            // CLR reads as zero because it is a write-one command.
            // EN is stored in timer_en.
            // ----------------------------------------------------

            10'h000: begin
                o_rdata = {30'b0, 1'b0, timer_en};
            end

            // ----------------------------------------------------
            // COUNT_LO: offset 0x004
            // Read-only
            // ----------------------------------------------------

            10'h001: begin
                o_rdata = timer_count[31:0];
            end

            // ----------------------------------------------------
            // COUNT_HI: offset 0x008
            // Read-only
            // ----------------------------------------------------

            10'h002: begin
                o_rdata = timer_count[63:32];
            end

            // ----------------------------------------------------
            // Reserved offsets
            // ----------------------------------------------------

            default: begin
                o_rdata = 32'b0;
            end

        endcase
    end

endmodule
