module tb_ImmGen;

    logic [31:0] i_instr;
    logic [2:0]  i_imm_sel;
    logic [31:0] o_imm;

    localparam logic [2:0] I = 3'b000;
    localparam logic [2:0] S = 3'b001;
    localparam logic [2:0] B = 3'b010;
    localparam logic [2:0] J = 3'b011;
    localparam logic [2:0] U = 3'b100;

    integer pass_count = 0;
    integer fail_count = 0;

    ImmGen dut (
        .i_instr   (i_instr),
        .i_imm_sel (i_imm_sel),
        .o_imm     (o_imm)
    );

    // Tinh immediate mong doi theo dinh dang RISC-V
    function automatic [31:0] reference_imm(
        input logic [31:0] instr,
        input logic [2:0]  sel
    );
        case (sel)
            I: reference_imm = {{20{instr[31]}}, instr[31:20]};

            S: reference_imm = {
                {20{instr[31]}}, instr[31:25], instr[11:7]
            };

            B: reference_imm = {
                {19{instr[31]}}, instr[31], instr[7],
                instr[30:25], instr[11:8], 1'b0
            };

            J: reference_imm = {
                {11{instr[31]}}, instr[31], instr[19:12],
                instr[20], instr[30:21], 1'b0
            };

            U: reference_imm = {instr[31:12], 12'b0};

            default: reference_imm = 32'b0;
        endcase
    endfunction

    // Kiem tra mot truong hop
    task automatic check_imm(
        input logic [31:0] instr,
        input logic [2:0]  sel,
        input string       name
    );
        logic [31:0] expected;
        begin
            i_instr   = instr;
            i_imm_sel = sel;
            expected  = reference_imm(instr, sel);

            #10;

            if (o_imm === expected) begin
                pass_count = pass_count + 1;
                $display(
                    "[PASS] %-12s instr=%h imm=%h",
                    name, instr, o_imm
                );
            end else begin
                fail_count = fail_count + 1;
                $display(
                    "[FAIL] %-12s instr=%h sel=%b expected=%h actual=%h",
                    name, instr, sel, expected, o_imm
                );
            end
        end
    endtask

    initial begin
        $display("===== START IMMGEN TEST =====");

        // Instr co bit dau = 0
        check_imm(32'h00A00093, I, "I positive");
        check_imm(32'h00A00093, S, "S positive");
        check_imm(32'h00A00093, B, "B positive");
        check_imm(32'h00A00093, J, "J positive");
        check_imm(32'h00A00093, U, "U positive");

        // Instr co bit dau = 1
        check_imm(32'hFEDCBA98, I, "I negative");
        check_imm(32'hFEDCBA98, S, "S negative");
        check_imm(32'hFEDCBA98, B, "B negative");
        check_imm(32'hFEDCBA98, J, "J negative");
        check_imm(32'hFEDCBA98, U, "U high bit");

        $display("==============================");
        $display("PASS: %0d", pass_count);
        $display("FAIL: %0d", fail_count);
        $display("==============================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        $finish;
    end
	 
	 initial begin
		$dumpfile ("sim/module/tb_ImmGen.vcd");
		$dumpvars (0,tb_ImmGen);
	 end	

endmodule
