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

    function automatic logic [31:0] i_add (input logic [4:0] rd, rs1, rs2);
        i_add = {7'b0000000, rs2, rs1, 3'b000, rd, OPCODE_R_TYPE};
    endfunction

    function automatic logic [31:0] i_lw (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_lw = enc_i(imm, rs1, 3'b010, rd, OPCODE_LOAD);
    endfunction

    function automatic logic [31:0] i_sw (input logic [4:0] rs1, rs2, input logic [11:0] imm);
        i_sw = {imm[11:5], rs2, rs1, 3'b010, imm[4:0], OPCODE_STORE};
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

    task automatic phase2_raw_hazard_now_fixed();
        $display("\n--- Phase 3: RAW Hazard (must now PASS with forwarding) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd5));
        imem.write_word(1, i_addi(5'd2, 5'd1, 12'd3));

        run_cycles(6);
        check_reg(1, 32'd5, "x1 = 5");
        check_reg(2, 32'd8, "x2 = x1+3 = 8 (EX/MEM forward)");
    endtask

    task automatic phase3_chained_dependency();
        $display("\n--- Phase 3: Chained Dependency ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd5));
        imem.write_word(1, i_addi(5'd2, 5'd1, 12'd3));
        imem.write_word(2, i_addi(5'd3, 5'd2, 12'd4));

        run_cycles(7);
        check_reg(1, 32'd5,  "x1 = 5");
        check_reg(2, 32'd8,  "x2 = x1+3 = 8 (back-to-back forward)");
        check_reg(3, 32'd12, "x3 = x2+4 = 12 (back-to-back forward)");
    endtask

    task automatic phase3_dual_source_dependency();
        $display("\n--- Phase 3: Dual-Source Dependency (rs1 and rs2) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd10));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd20));
        imem.write_word(2, i_add (5'd3, 5'd1, 5'd2));

        run_cycles(7);
        check_reg(3, 32'd30, "x3 = x1+x2 = 30 (dual forward, rs1 and rs2)");
    endtask

    task automatic phase3_mem_wb_forward();
        $display("\n--- Phase 3: MEM/WB Forwarding (gap of one instruction) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd5));
        imem.write_word(1, i_addi(5'd4, 5'd0, 12'd99));
        imem.write_word(2, i_addi(5'd2, 5'd1, 12'd3));

        run_cycles(7);
        check_reg(2, 32'd8, "x2 = x1+3 = 8 (MEM/WB forward path)");
    endtask

    task automatic phase4_load_use_stall();
        $display("\n--- Phase 4: Load-Use Hazard (stall required) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd100)); // x1 = base addr 100
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd42));  // x2 = 42
        imem.write_word(2, i_sw  (5'd1, 5'd2, 12'd0));   // mem[100] = 42
        imem.write_word(3, i_lw  (5'd3, 5'd1, 12'd0));   // x3 = mem[100] (load)
        imem.write_word(4, i_addi(5'd4, 5'd3, 12'd1));   // x4 = x3+1 -- LOAD-USE HAZARD

        run_cycles(11);
        check_reg(3, 32'd42, "x3 = mem[100] = 42 (load completed)");
        check_reg(4, 32'd43, "x4 = x3+1 = 43 (load-use hazard resolved via stall)");
    endtask

    task automatic phase4_no_hazard_no_stall();
        $display("\n--- Phase 4: No Hazard -- confirm no unnecessary stall ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd100));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd42));
        imem.write_word(2, i_sw  (5'd1, 5'd2, 12'd0));
        imem.write_word(3, i_lw  (5'd3, 5'd1, 12'd0));
        imem.write_word(4, i_addi(5'd5, 5'd0, 12'd7)); // independent -- no hazard

        run_cycles(9);
        check_reg(3, 32'd42, "x3 = mem[100] = 42");
        check_reg(5, 32'd7,  "x5 = 7 (unrelated instruction, no stall needed)");
    endtask

    task automatic phase4_wb_id_gap_of_three();
        $display("\n--- Phase 4: WB->ID Gap-of-3 Dependency (regfile bypass) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd100)); // x1 = 100
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd42));  // x2 = 42
        imem.write_word(2, i_sw  (5'd1, 5'd2, 12'd0));   // mem[100] = 42
        imem.write_word(3, i_lw  (5'd3, 5'd1, 12'd0));   // x3 = mem[100] = 42 -- reads x1, gap of 3 from I0

        run_cycles(9);
        check_reg(3, 32'd42, "x3 = mem[100] = 42 (gap-of-3 read of x1 resolved by bypass)");
    endtask

    initial begin
        rst_n = 1'b0;

        phase2_raw_hazard_now_fixed();
        phase3_chained_dependency();
        phase3_dual_source_dependency();
        phase3_mem_wb_forward();
        phase4_load_use_stall();
        phase4_no_hazard_no_stall();
        phase4_wb_id_gap_of_three();

        $display("\n===================================");
        $display("Pipeline Phase 4: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("===================================");
        $finish;
    end

endmodule

`default_nettype wire
