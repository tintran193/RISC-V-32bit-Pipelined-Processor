// ============================================================================
// board_wrapper_DE2.sv
// Top-level wrapper for the Terasic Altera DE2 board.
//
// Board connections:
//   CLOCK_50 : 50 MHz system clock
//   KEY[0]   : active-low system reset
//   KEY[3:1] : active-low user buttons -> milestone3.i_key[3:1]
//   SW[17:0] : slide switches
//   LEDR     : 18 red LEDs
//   LEDG     : 9 green LEDs (LEDG[8] is used as the LEDB[0] status indicator)
//   HEX0-7  : seven-segment displays
//   GPIO_0  : first 32 pins of the 36-bit GPIO_0 expansion header
//
// The wrapper contains only clock/reset handling, input synchronizers,
// external pin buffering, and physical-board I/O mapping.
// It does not implement application algorithms.
// ============================================================================

module DE2_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,

    output wire [17:0] LEDR,
    output wire [8:0]  LEDG,

    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
    output wire [6:0]  HEX4,
    output wire [6:0]  HEX5,
    output wire [6:0]  HEX6,
    output wire [6:0]  HEX7,

    inout  wire [35:0] GPIO_0
);

    // ========================================================================
    // 1. Internal signals
    // ========================================================================

    wire        reset_n;
    logic [1:0] reset_sync;

    logic [17:0] sw_meta;
    logic [17:0] sw_sync;

    logic [2:0] key_meta;
    logic [2:0] key_sync;
    wire  [3:0] key_to_mcu;

    wire  [31:0] gpio_pin_async;
    logic [31:0] gpio_meta;
    logic [31:0] gpio_sync;

    wire [31:0] mcu_ledr;
    wire [31:0] mcu_ledg;
    wire [31:0] mcu_ledb;

    wire [31:0] mcu_gpio_out;
    wire [31:0] mcu_gpio_dir;

    // ========================================================================
    // 2. Reset synchronizer
    //
    // DE2 pushbuttons are active-low. KEY[0] is reserved for reset in the
    // Milestone 3 example wrapper. Reset assertion is asynchronous; reset
    // release is synchronized to CLOCK_50 through two flip-flops.
    // ========================================================================

    always_ff @(posedge CLOCK_50 or negedge KEY[0]) begin
        if (!KEY[0]) begin
            reset_sync <= 2'b00;
        end
        else begin
            reset_sync <= {reset_sync[0], 1'b1};
        end
    end

    assign reset_n = reset_sync[1];

    // ========================================================================
    // 3. Switch synchronizer (18 bits)
    //
    // Switches are asynchronous inputs. Their logic polarity is unchanged.
    // ========================================================================

    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            sw_meta <= 18'b0;
            sw_sync <= 18'b0;
        end
        else begin
            sw_meta <= SW;
            sw_sync <= sw_meta;
        end
    end

    // ========================================================================
    // 4. Button synchronizer (KEY[3:1])
    //
    // KEY inputs are active-low. Keep that polarity for milestone3.i_key;
    // the sw_btn device converts pressed buttons to logic 1.
    // KEY[0] is the reset button, therefore i_key[0] is tied inactive-high.
    // ========================================================================

    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            key_meta <= 3'b111;
            key_sync <= 3'b111;
        end
        else begin
            key_meta <= KEY[3:1];
            key_sync <= key_meta;
        end
    end

    assign key_to_mcu = {key_sync, 1'b1};

    // ========================================================================
    // 5. GPIO tri-state buffers and input synchronizer
    //
    // GPIO_0[31:0] are connected to the MCU's 32 GPIO pins.
    // GPIO_0[35:32] are unused by this wrapper and remain high impedance.
    // A pin is driven only when its GPIO_DIR bit is 1.
    // ========================================================================

    assign gpio_pin_async = GPIO_0[31:0];

    // GPIO output-enable buffers. Each pin is high-Z in input mode.
    assign GPIO_0[0]  = mcu_gpio_dir[0]  ? mcu_gpio_out[0]  : 1'bz;
    assign GPIO_0[1]  = mcu_gpio_dir[1]  ? mcu_gpio_out[1]  : 1'bz;
    assign GPIO_0[2]  = mcu_gpio_dir[2]  ? mcu_gpio_out[2]  : 1'bz;
    assign GPIO_0[3]  = mcu_gpio_dir[3]  ? mcu_gpio_out[3]  : 1'bz;
    assign GPIO_0[4]  = mcu_gpio_dir[4]  ? mcu_gpio_out[4]  : 1'bz;
    assign GPIO_0[5]  = mcu_gpio_dir[5]  ? mcu_gpio_out[5]  : 1'bz;
    assign GPIO_0[6]  = mcu_gpio_dir[6]  ? mcu_gpio_out[6]  : 1'bz;
    assign GPIO_0[7]  = mcu_gpio_dir[7]  ? mcu_gpio_out[7]  : 1'bz;
    assign GPIO_0[8]  = mcu_gpio_dir[8]  ? mcu_gpio_out[8]  : 1'bz;
    assign GPIO_0[9]  = mcu_gpio_dir[9]  ? mcu_gpio_out[9]  : 1'bz;
    assign GPIO_0[10] = mcu_gpio_dir[10] ? mcu_gpio_out[10] : 1'bz;
    assign GPIO_0[11] = mcu_gpio_dir[11] ? mcu_gpio_out[11] : 1'bz;
    assign GPIO_0[12] = mcu_gpio_dir[12] ? mcu_gpio_out[12] : 1'bz;
    assign GPIO_0[13] = mcu_gpio_dir[13] ? mcu_gpio_out[13] : 1'bz;
    assign GPIO_0[14] = mcu_gpio_dir[14] ? mcu_gpio_out[14] : 1'bz;
    assign GPIO_0[15] = mcu_gpio_dir[15] ? mcu_gpio_out[15] : 1'bz;
    assign GPIO_0[16] = mcu_gpio_dir[16] ? mcu_gpio_out[16] : 1'bz;
    assign GPIO_0[17] = mcu_gpio_dir[17] ? mcu_gpio_out[17] : 1'bz;
    assign GPIO_0[18] = mcu_gpio_dir[18] ? mcu_gpio_out[18] : 1'bz;
    assign GPIO_0[19] = mcu_gpio_dir[19] ? mcu_gpio_out[19] : 1'bz;
    assign GPIO_0[20] = mcu_gpio_dir[20] ? mcu_gpio_out[20] : 1'bz;
    assign GPIO_0[21] = mcu_gpio_dir[21] ? mcu_gpio_out[21] : 1'bz;
    assign GPIO_0[22] = mcu_gpio_dir[22] ? mcu_gpio_out[22] : 1'bz;
    assign GPIO_0[23] = mcu_gpio_dir[23] ? mcu_gpio_out[23] : 1'bz;
    assign GPIO_0[24] = mcu_gpio_dir[24] ? mcu_gpio_out[24] : 1'bz;
    assign GPIO_0[25] = mcu_gpio_dir[25] ? mcu_gpio_out[25] : 1'bz;
    assign GPIO_0[26] = mcu_gpio_dir[26] ? mcu_gpio_out[26] : 1'bz;
    assign GPIO_0[27] = mcu_gpio_dir[27] ? mcu_gpio_out[27] : 1'bz;
    assign GPIO_0[28] = mcu_gpio_dir[28] ? mcu_gpio_out[28] : 1'bz;
    assign GPIO_0[29] = mcu_gpio_dir[29] ? mcu_gpio_out[29] : 1'bz;
    assign GPIO_0[30] = mcu_gpio_dir[30] ? mcu_gpio_out[30] : 1'bz;
    assign GPIO_0[31] = mcu_gpio_dir[31] ? mcu_gpio_out[31] : 1'bz;

    assign GPIO_0[35:32] = 4'bzzzz;

    // Synchronize external GPIO levels before feeding the MCU.
    always_ff @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            gpio_meta <= 32'b0;
            gpio_sync <= 32'b0;
        end
        else begin
            gpio_meta <= gpio_pin_async;
            gpio_sync <= gpio_meta;
        end
    end

    // ========================================================================
    // 6. Instantiate the Milestone 3 MCU
    // ========================================================================

    milestone3 u_milestone3 (
        .i_clk          (CLOCK_50),
        .i_rstn         (reset_n),

        .i_sw           (sw_sync),
        .i_key          (key_to_mcu),

        .o_ledr         (mcu_ledr),
        .o_ledg         (mcu_ledg),
        .o_ledb         (mcu_ledb),

        .o_hex0         (HEX0),
        .o_hex1         (HEX1),
        .o_hex2         (HEX2),
        .o_hex3         (HEX3),
        .o_hex4         (HEX4),
        .o_hex5         (HEX5),
        .o_hex6         (HEX6),
        .o_hex7         (HEX7),

        .i_gpio_in      (gpio_sync),
        .o_gpio_out     (mcu_gpio_out),
        .o_gpio_dir     (mcu_gpio_dir),

        // Simulation-only outputs are not used on the FPGA board.
        .o_event_valid  (),
        .o_event_data   (),
        .o_print_valid  (),
        .o_print_char   (),
        .o_halt         (),
        .o_db_valid     ()
    );

    // ========================================================================
    // 7. Map MCU LED registers to the physical DE2 indicators
    //
    // DE2 has 18 red LEDs and 9 green LEDs. This wrapper maps:
    //   LEDR[17:0] <- MCU LEDR[17:0]
    //   LEDG[7:0]  <- MCU LEDG[7:0]
    //   LEDG[8]    <- MCU LEDB[0] (application-done indicator)
    //
    // The DE2 board has no dedicated blue LED bank.
    // ========================================================================

    assign LEDR    = mcu_ledr[17:0];
    assign LEDG[7:0] = mcu_ledg[7:0];
    assign LEDG[8]   = mcu_ledb[0];

endmodule
