
`ifndef IMEM_START_ADDR
    `define IMEM_START_ADDR 32'h8000_0000
`endif

`ifndef IMEM_ADDR_WIDTH
    `define IMEM_ADDR_WIDTH 26
`endif

`ifndef DMEM_START_ADDR
    `define DMEM_START_ADDR 32'h8400_0000
`endif

`ifndef DMEM_ADDR_WIDTH
    `define DMEM_ADDR_WIDTH 14
`endif

`ifndef PROGRAMFILE
    `define PROGRAMFILE "program.hex"
`endif


module milestone3 (

    input  logic        i_clk,
    input  logic        i_rstn,

    input  logic [17:0] i_sw,
    input  logic [3:0]  i_key,

    output logic [31:0] o_ledr,
    output logic [31:0] o_ledg,
    output logic [31:0] o_ledb,

    output logic [6:0] o_hex0,
    output logic [6:0] o_hex1,
    output logic [6:0] o_hex2,
    output logic [6:0] o_hex3,
    output logic [6:0] o_hex4,
    output logic [6:0] o_hex5,
    output logic [6:0] o_hex6,
    output logic [6:0] o_hex7,

    input  logic [31:0] i_gpio_in,
    output logic [31:0] o_gpio_out,
    output logic [31:0] o_gpio_dir,

    output logic        o_event_valid,
    output logic [31:0] o_event_data,

    output logic        o_print_valid,
    output logic [7:0]  o_print_char,

    output logic        o_halt,
    output logic        o_db_valid
);
    // CPU <-> IMEM
    logic [31:0] imem_addr;
    logic [31:0] imem_rdata;

    // CPU <-> Simple Bus
    logic [31:0] core_bus_addr;
    logic [31:0] core_bus_wdata;
    logic [3:0]  core_bus_bmsk;
    logic        core_bus_wren;

    logic [31:0] bus_core_rdata;

    // Simple Bus <-> DMEM
    logic [31:0] dmem_addr;
    logic [31:0] dmem_wdata;
    logic [3:0]  dmem_bmsk;
    logic        dmem_wren;
    logic [31:0] dmem_rdata;

    // Simple Bus <-> I/O Devices
    logic [11:0] dev_addr;
    logic [31:0] dev_wdata;
    logic [3:0]  dev_bmsk;

    // Write enables
    logic led_wren;
    logic hex_wren;
    logic timer_wren;
    logic gpio_wren;
    logic tb_wren;


    // Read data from devices
    logic [31:0] led_rdata;
    logic [31:0] hex_rdata;

    logic [31:0] sw_rdata;
    logic [31:0] key_rdata;

    logic [31:0] timer_rdata;
    logic [31:0] gpio_rdata;

    // Single-cycle CPU
    singlecycle u_singlecycle (
        .i_clk         (i_clk),
        .i_rstn        (i_rstn),

        // Instruction fetch interface
        .i_imem_rdata  (imem_rdata),
        .o_imem_addr   (imem_addr),

        // Data access interface -> Simple Bus
        .i_dmem_rdata  (bus_core_rdata),
        .o_dmem_addr   (core_bus_addr),
        .o_dmem_wdata  (core_bus_wdata),
        .o_dmem_bmsk   (core_bus_bmsk),
        .o_dmem_wren   (core_bus_wren),

        // Debug
        .o_db_valid    (o_db_valid)
    );


    // ============================================================
    // 9. Instruction Memory
    // ============================================================

    imem #(
        .START_ADDR (`IMEM_START_ADDR),
        .ADDR_WIDTH (`IMEM_ADDR_WIDTH),
        .PROGRAMFILE(`PROGRAMFILE)
    ) u_imem (
        .i_clk  (i_clk),
        .i_addr (imem_addr),
        .o_data (imem_rdata)
    );


    // ============================================================
    // 10. Simple Bus
    // ============================================================

    simple_bus u_simple_bus (

        // CPU interface
        .i_core_bus_addr  (core_bus_addr),
        .i_core_bus_wdata (core_bus_wdata),
        .i_core_bus_bmsk  (core_bus_bmsk),
        .i_core_bus_wren  (core_bus_wren),
        .o_bus_core_rdata (bus_core_rdata),

        // DMEM interface
        .i_dmem_rdata (dmem_rdata),
        .o_dmem_addr  (dmem_addr),
        .o_dmem_wdata (dmem_wdata),
        .o_dmem_bmsk  (dmem_bmsk),
        .o_dmem_wren  (dmem_wren),

        // Shared device interface
        .o_dev_addr  (dev_addr),
        .o_dev_wdata (dev_wdata),
        .o_dev_bmsk  (dev_bmsk),

        // Individual write enables
        .o_led_wren   (led_wren),
        .o_hex_wren   (hex_wren),
        .o_sw_wren    (),
        .o_key_wren   (),
        .o_timer_wren (timer_wren),
        .o_gpio_wren  (gpio_wren),
        .o_tb_wren    (tb_wren),

        // Device read data
        .i_led_rdata   (led_rdata),
        .i_hex_rdata   (hex_rdata),
        .i_sw_rdata    (sw_rdata),
        .i_key_rdata   (key_rdata),
        .i_timer_rdata (timer_rdata),
        .i_gpio_rdata  (gpio_rdata)
    );


    // ============================================================
    // 11. Data Memory
    // ============================================================

    dmem #(
        .START_ADDR (`DMEM_START_ADDR),
        .ADDR_WIDTH (`DMEM_ADDR_WIDTH)
    ) u_dmem (
        .i_clk   (i_clk),
        .i_addr  (dmem_addr),
        .i_wdata (dmem_wdata),
        .i_bmsk  (dmem_bmsk),
        .i_wren  (dmem_wren),
        .o_rdata (dmem_rdata)
    );


    // ============================================================
    // 12. LED device
    // ============================================================

    led u_led (
        .i_clk   (i_clk),
        .i_rstn  (i_rstn),

        .i_addr  (dev_addr),
        .i_wdata (dev_wdata),
        .i_bmsk  (dev_bmsk),
        .i_wren  (led_wren),

        .o_rdata (led_rdata),

        .o_ledr  (o_ledr),
        .o_ledg  (o_ledg),
        .o_ledb  (o_ledb)
    );


    // ============================================================
    // 13. HEX display device
    // ============================================================

    hex_display u_hex_display (
        .i_clk   (i_clk),
        .i_rstn  (i_rstn),

        .i_addr  (dev_addr),
        .i_wdata (dev_wdata),
        .i_bmsk  (dev_bmsk),
        .i_wren  (hex_wren),

        .o_rdata (hex_rdata),

        .o_hex0  (o_hex0),
        .o_hex1  (o_hex1),
        .o_hex2  (o_hex2),
        .o_hex3  (o_hex3),
        .o_hex4  (o_hex4),
        .o_hex5  (o_hex5),
        .o_hex6  (o_hex6),
        .o_hex7  (o_hex7)
    );


    // ============================================================
    // 14. Switch and button device
    // ============================================================

    // Physical KEY pins are active-low.
    // sw_btn converts pressed button -> logic 1.

    sw_btn u_sw_btn (
        .i_addr      (dev_addr),
        .i_sw        (i_sw),
        .i_btn       (i_key),

        .o_sw_rdata  (sw_rdata),
        .o_btn_rdata (key_rdata)
    );


    // ============================================================
    // 15. Timer device
    // ============================================================

    timer u_timer (
        .i_clk   (i_clk),
        .i_rstn  (i_rstn),

        .i_addr  (dev_addr),
        .i_wdata (dev_wdata),
        .i_bmsk  (dev_bmsk),
        .i_wren  (timer_wren),

        .o_rdata (timer_rdata)
    );


    // ============================================================
    // 16. GPIO device
    // ============================================================

    gpio_ctrl u_gpio_ctrl (
        .i_clk      (i_clk),
        .i_rstn     (i_rstn),

        .i_addr     (dev_addr),
        .i_wdata    (dev_wdata),
        .i_bmsk     (dev_bmsk),
        .i_wren     (gpio_wren),

        .i_gpio_in  (i_gpio_in),

        .o_rdata    (gpio_rdata),
        .o_gpio_out (o_gpio_out),
        .o_gpio_dir (o_gpio_dir)
    );


    // ============================================================
    // 17. Testbench device
    // ============================================================

    // Assumed common device interface:
    // i_clk, i_rstn, i_addr, i_wdata, i_bmsk, i_wren.
    // Check the supplied tb_device.sv port names before compiling.

    tb_device u_tb_device (
        .i_clk         (i_clk),
        .i_rstn        (i_rstn),

        .i_addr        (dev_addr),
        .i_wdata       (dev_wdata),
        .i_bmsk        (dev_bmsk),
        .i_wren        (tb_wren),

        .o_event_valid (o_event_valid),
        .o_event_data  (o_event_data),

        .o_print_valid (o_print_valid),
        .o_print_char  (o_print_char),

        .o_halt        (o_halt)
    );

endmodule
