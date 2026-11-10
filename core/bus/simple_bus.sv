/*
// CPU -> Bus
.o_dmem_addr  (core_bus_addr),
.o_dmem_wdata (core_bus_wdata),
.o_dmem_bmsk  (core_bus_bmsk),
.o_dmem_wren  (core_bus_wren),

// Bus -> CPU
.i_dmem_rdata (bus_core_rdata)
*/

module simple_bus (
    // BUS <-> CPU
    input logic [31:0] i_core_bus_addr,
    input logic [31:0] i_core_bus_wdata,
    input logic [3:0] i_core_bus_bmsk,
    input logic i_core_bus_wren,

    output logic [31:0] o_bus_core_rdata,

    // BUS <-> DMEM
    input logic [31:0] i_dmem_rdata,
    
    output logic [31:0] o_dmem_addr,
    output logic [31:0] o_dmem_wdata,
    output logic [3:0] o_dmem_bmsk,
    output logic o_dmem_wren,

    // BUS <-> I/O Devices
    // Shared device interface
    output logic [11:0] o_dev_addr, //offset address
    output logic [31:0] o_dev_wdata,
    output logic [3:0]  o_dev_bmsk,
    // Individual write enable
    output logic o_led_wren,
    output logic o_hex_wren,
    output logic o_sw_wren,
    output logic o_key_wren,
    output logic o_timer_wren,
    output logic o_gpio_wren,
    output logic o_tb_wren,
    // Read data from devices
    input logic [31:0] i_led_rdata,
    input logic [31:0] i_hex_rdata,
    input logic [31:0] i_sw_rdata,
    input logic [31:0] i_key_rdata,
    input logic [31:0] i_timer_rdata,
    input logic [31:0] i_gpio_rdata
);

    //Address Decode
    logic dmem_sel;
    logic io_sel;

    logic led_sel;
    logic hex_sel;
    logic sw_sel;
    logic key_sel;
    logic timer_sel;
    logic gpio_sel;
    logic tb_sel;

    // DMEM: 0x8400_0000 - 0x8400_3FFF: 16 KiB
    assign dmem_sel = (i_core_bus_addr[31:14] == 18'h21000); //1000 0100 0000 0000 00|11 1111 1111 1111
    // I/O: 0x4000_0000 - 0x4000_FFFF: 64 KiB
    assign io_sel = (i_core_bus_addr[31:16] == 16'h4000); // 01000 0000 0000 0000 |1111 1111 1111 1111

    assign led_sel = io_sel && (i_core_bus_addr[15:12] == 4'h0);
    assign hex_sel = io_sel && (i_core_bus_addr[15:12] == 4'h1);
    assign sw_sel = io_sel && (i_core_bus_addr[15:12] == 4'h2);
    assign key_sel = io_sel && (i_core_bus_addr[15:12] == 4'h3);
    assign timer_sel = io_sel && (i_core_bus_addr[15:12] == 4'h4);
    assign gpio_sel = io_sel && (i_core_bus_addr[15:12] == 4'h5);
    assign tb_sel = io_sel && (i_core_bus_addr[15:12] == 4'hF);

    // Device Interface
    assign o_dev_addr  = i_core_bus_addr[11:0];
    assign o_dev_wdata = i_core_bus_wdata;
    assign o_dev_bmsk  = i_core_bus_bmsk;

    // Write Demux
    //DMEM
    assign o_dmem_addr  = i_core_bus_addr;
    assign o_dmem_wdata = i_core_bus_wdata;
    assign o_dmem_bmsk  = i_core_bus_bmsk;
    assign o_dmem_wren  = i_core_bus_wren & dmem_sel; 
    //IO 
    assign o_led_wren   = i_core_bus_wren & led_sel;
    assign o_hex_wren   = i_core_bus_wren & hex_sel;
    assign o_sw_wren    = i_core_bus_wren & sw_sel;
    assign o_key_wren   = i_core_bus_wren & key_sel;
    assign o_timer_wren = i_core_bus_wren & timer_sel;
    assign o_gpio_wren  = i_core_bus_wren & gpio_sel;
    assign o_tb_wren    = i_core_bus_wren & tb_sel;

    // Read Mux
    always_comb begin
        // Default: unmapped address returns zero
        o_bus_core_rdata = 32'b0;

        if (dmem_sel) begin
            o_bus_core_rdata = i_dmem_rdata;
        end
        else if (io_sel) begin

            case (core_bus_addr[15:12])

                4'h0: o_bus_core_rdata = i_led_rdata;
                4'h1: o_bus_core_rdata = i_hex_rdata;
                4'h2: o_bus_core_rdata = i_sw_rdata;
                4'h3: o_bus_core_rdata = i_key_rdata;
                4'h4: o_bus_core_rdata = i_timer_rdata;
                4'h5: o_bus_core_rdata = i_gpio_rdata;

                // 0x4000F000 - 0x4000FFFF
                // Testbench device is write-only.
                // Its read value is zero.
                4'hF: o_bus_core_rdata = 32'b0;

                // Reserved address ranges
                default: o_bus_core_rdata = 32'b0;
            endcase
        end
    end

endmodule