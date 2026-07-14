`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module rv32i_pipeline_core_tb;

    logic clk;
    logic rst_n;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    logic [XLEN-1:0]    imem_addr;
    logic [INSTR_W-1:0] imem_rdata;

    logic [XLEN-1:0]    dmem_addr;
    logic [XLEN-1:0]    dmem_wdata;
    logic [3:0]         dmem_be;
    logic                dmem_we;
    logic                dmem_re;
    logic [XLEN-1:0]    dmem_rdata;

    int pass_count = 0;
    int fail_count = 0;

    rv32i_pipeline_core dut (
        .clk          (clk),
        .rst_n        (rst_n),
        .imem_addr_o  (imem_addr),
        .imem_rdata_i (imem_rdata),
        .dmem_addr_o  (dmem_addr),
        .dmem_wdata_o (dmem_wdata),
        .dmem_be_o    (dmem_be),
        .dmem_we_o    (dmem_we),
        .dmem_re_o    (dmem_re),
        .dmem_rdata_i (dmem_rdata)
    );

    instruction_memory_model #(
        .MEM_DEPTH_WORDS (256)
    ) imem (
        .addr_i  (imem_addr),
        .instr_o (imem_rdata)
    );

    data_memory_model #(
        .MEM_DEPTH_BYTES (1024)
    ) dmem (
        .clk_i   (clk),
        .addr_i  (dmem_addr),
        .wdata_i (dmem_wdata),
        .be_i    (dmem_be),
        .we_i    (dmem_we),
        .re_i    (dmem_re),
        .rdata_o (dmem_rdata)
    );

    function automatic logic [31:0] enc_i
        (input logic [11:0] imm, input logic [4:0] rs1,
         input logic [2:0] funct3, input logic [4:0] rd, input logic [6:0] opcode);
        enc_i = {imm, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] i_addi (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_addi = enc_i(imm, rs1, 3'b000, rd, OPCODE_I_TYPE);
    endfunction

    function automatic logic [31:0] nop();
        nop = i_addi(5'd0, 5'd0, 12'd0);
    endfunction

    task automatic apply_reset();
        int k;
        rst_n = 1'b0;
        for (k = 0; k < 32; k = k + 1) begin
            imem.write_word(k, nop());
        end
        @(posedge clk);
        @(posedge clk);
        rst_n = 1'b1;
    endtask

    task automatic run_cycles(input int n);
        int k;
        for (k = 0; k < n; k = k + 1) @(posedge clk);
        #1;
    endtask

    task automatic check_reg(input int idx, input logic [XLEN-1:0] expected, input string name);
        logic [XLEN-1:0] actual;
        actual = dut.u_id_stage.u_regfile.regs[idx];
        if (actual !== expected) begin
            $display("FAIL: %s -- x%0d = 0x%08h, expected 0x%08h", name, idx, actual, expected);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: %s -- x%0d = 0x%08h", name, idx, actual);
            pass_count = pass_count + 1;
        end
    endtask

    task automatic phase1a_progression();
        $display("\n--- Phase 1a: Instruction Progression ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd11));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd22));
        imem.write_word(2, i_addi(5'd3, 5'd0, 12'd33));
        imem.write_word(3, i_addi(5'd4, 5'd0, 12'd44));
        imem.write_word(4, i_addi(5'd5, 5'd0, 12'd55));

        #1;
        if (imem_addr !== RESET_VECTOR) begin
            $display("FAIL: IF not fetching from RESET_VECTOR after reset");
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: IF fetching from RESET_VECTOR after reset");
            pass_count = pass_count + 1;
        end

        run_cycles(5);
        check_reg(1, 32'd11, "I1 (addi x1,x0,11) reaches WB after 5 cycles");

        run_cycles(1);
        check_reg(2, 32'd22, "I2 reaches WB one cycle later");

        run_cycles(1);
        check_reg(3, 32'd33, "I3 reaches WB one cycle later");

        run_cycles(1);
        check_reg(4, 32'd44, "I4 reaches WB one cycle later");

        run_cycles(1);
        check_reg(5, 32'd55, "I5 reaches WB one cycle later");
    endtask

    task automatic phase1b_independent_block();
        $display("\n--- Phase 1b: Independent Instructions (drained) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd5));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd7));
        imem.write_word(2, i_addi(5'd3, 5'd0, 12'd9));

        run_cycles(8);
        check_reg(1, 32'd5, "x1 = 5 (fully drained)");
        check_reg(2, 32'd7, "x2 = 7 (fully drained)");
        check_reg(3, 32'd9, "x3 = 9 (fully drained)");
    endtask

    task automatic phase2_raw_hazard_exposure();
        logic [XLEN-1:0] x2_actual;
        $display("\n--- Phase 2: RAW Hazard Exposure (expected to be WRONG) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd5));
        imem.write_word(1, i_addi(5'd2, 5'd1, 12'd3));

        run_cycles(6);
        x2_actual = dut.u_id_stage.u_regfile.regs[2];

        $display("x1 (should be 5)            = 0x%08h", dut.u_id_stage.u_regfile.regs[1]);
        $display("x2 (correct answer is 8)    = 0x%08h", x2_actual);

        if (x2_actual == 32'd8) begin
            $display("UNEXPECTED: x2 is correct without forwarding -- investigate why.");
        end else begin
            $display("CONFIRMED: x2 = %0d, not 8 -- RAW hazard reproduced as expected.", x2_actual);
            $display("Root cause: addi x2,x1,3 read x1 from the regfile in ID while");
            $display("addi x1,x0,5 was still in EX -- 3 stages away from writing x1 back.");
        end
    endtask

    initial begin
        rst_n = 1'b0;

        phase1a_progression();
        phase1b_independent_block();
        phase2_raw_hazard_exposure();

        $display("\n===================================");
        $display("Pipeline Phase 1 bring-up: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("===================================");
        $finish;
    end

endmodule

`default_nettype wire
