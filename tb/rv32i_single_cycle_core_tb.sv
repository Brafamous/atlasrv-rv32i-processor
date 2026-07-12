`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module rv32i_single_cycle_core_tb;

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

    rv32i_single_cycle_core dut (
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

    function automatic logic [31:0] enc_r
        (input logic [6:0] funct7, input logic [4:0] rs2, rs1,
         input logic [2:0] funct3, input logic [4:0] rd, input logic [6:0] opcode);
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] enc_i
        (input logic [11:0] imm, input logic [4:0] rs1,
         input logic [2:0] funct3, input logic [4:0] rd, input logic [6:0] opcode);
        enc_i = {imm, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] enc_s
        (input logic [11:0] imm, input logic [4:0] rs2, rs1,
         input logic [2:0] funct3, input logic [6:0] opcode);
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction

    function automatic logic [31:0] enc_b
        (input logic [12:0] imm, input logic [4:0] rs2, rs1,
         input logic [2:0] funct3, input logic [6:0] opcode);
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    function automatic logic [31:0] enc_j
        (input logic [20:0] imm, input logic [4:0] rd, input logic [6:0] opcode);
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    function automatic logic [31:0] i_addi (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_addi = enc_i(imm, rs1, 3'b000, rd, OPCODE_I_TYPE);
    endfunction
    function automatic logic [31:0] i_add (input logic [4:0] rd, rs1, rs2);
        i_add = enc_r(7'b0000000, rs2, rs1, 3'b000, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_sw (input logic [4:0] rs1, rs2, input logic [11:0] imm);
        i_sw = enc_s(imm, rs2, rs1, 3'b010, OPCODE_STORE);
    endfunction
    function automatic logic [31:0] i_lw (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_lw = enc_i(imm, rs1, 3'b010, rd, OPCODE_LOAD);
    endfunction
    function automatic logic [31:0] i_beq (input logic [4:0] rs1, rs2, input logic [12:0] imm);
        i_beq = enc_b(imm, rs2, rs1, 3'b000, OPCODE_BRANCH);
    endfunction
    function automatic logic [31:0] i_jal (input logic [4:0] rd, input logic [20:0] imm);
        i_jal = enc_j(imm, rd, OPCODE_JAL);
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
        actual = dut.u_regfile.regs[idx];
        if (actual !== expected) begin
            $display("FAIL: %s -- x%0d = 0x%08h, expected 0x%08h", name, idx, actual, expected);
            fail_count = fail_count + 1;
            $fatal;
        end else begin
            $display("PASS: %s -- x%0d = 0x%08h", name, idx, actual);
            pass_count = pass_count + 1;
        end
    endtask

    task automatic check_pc(input logic [XLEN-1:0] expected, input string name);
        if (imem_addr !== expected) begin
            $display("FAIL: %s -- pc = 0x%08h, expected 0x%08h", name, imem_addr, expected);
            fail_count = fail_count + 1;
            $fatal;
        end else begin
            $display("PASS: %s -- pc = 0x%08h", name, imem_addr);
            pass_count = pass_count + 1;
        end
    endtask

    task automatic phase1_reset();
        $display("\n--- Phase 1: Reset ---");
        apply_reset();
        #1;
        check_pc(RESET_VECTOR, "PC resets to RESET_VECTOR");
        if (dmem_we !== 1'b0) begin
            $display("FAIL: dmem_we asserted during reset");
            fail_count = fail_count + 1; $fatal;
        end else begin
            $display("PASS: no data-memory write during reset");
            pass_count = pass_count + 1;
        end
    endtask

    task automatic phase2_sequential_fetch();
        $display("\n--- Phase 2: Sequential Fetch ---");
        apply_reset();

        #1; check_pc(32'h0000_0000, "Fetch PC=0");
        run_cycles(1); check_pc(32'h0000_0004, "Fetch PC=4");
        run_cycles(1); check_pc(32'h0000_0008, "Fetch PC=8");
        run_cycles(1); check_pc(32'h0000_000C, "Fetch PC=C");
    endtask

    task automatic phase3_first_execute();
        $display("\n--- Phase 3: First Execute ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd5));

        run_cycles(1);
        check_reg(1, 32'd5, "addi x1,x0,5");
        check_reg(0, 32'd0, "x0 remains zero");
    endtask

    task automatic phase4_arithmetic();
        $display("\n--- Phase 4: Arithmetic ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd5));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd7));
        imem.write_word(2, i_add (5'd3, 5'd1, 5'd2));

        run_cycles(3);
        check_reg(1, 32'd5,  "x1 = 5");
        check_reg(2, 32'd7,  "x2 = 7");
        check_reg(3, 32'd12, "x3 = x1+x2 = 12");
    endtask

    task automatic phase5_load_store();
        $display("\n--- Phase 5: Load / Store ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd100));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd42));
        imem.write_word(2, i_sw  (5'd1, 5'd2, 12'd0));
        imem.write_word(3, i_lw  (5'd3, 5'd1, 12'd0));

        run_cycles(4);
        check_reg(3, 32'd42, "lw reflects sw (x3 = 42)");
    endtask

    task automatic phase6_branch();
        $display("\n--- Phase 6: Branch ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd1));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd1));
        imem.write_word(2, i_beq (5'd1, 5'd2, 13'sd8));
        imem.write_word(3, i_addi(5'd3, 5'd0, 12'd99));
        imem.write_word(4, i_addi(5'd4, 5'd0, 12'd5));

        run_cycles(4);
        check_reg(3, 32'd0, "x3 untouched -- BEQ skipped pc=12");
        check_reg(4, 32'd5, "x4 = 5 -- landed correctly after taken BEQ");
    endtask

    task automatic phase7_jal();
        $display("\n--- Phase 7: JAL ---");
        apply_reset();
        imem.write_word(0, i_jal (5'd1, 21'sd8));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd99));
        imem.write_word(2, i_addi(5'd3, 5'd0, 12'd5));

        run_cycles(2);
        check_reg(1, 32'd4, "jal link = pc+4 = 4");
        check_reg(2, 32'd0, "x2 untouched -- JAL skipped pc=4");
        check_reg(3, 32'd5, "x3 = 5 -- landed correctly after JAL");
    endtask

    initial begin
        rst_n = 1'b0;

        phase1_reset();
        phase2_sequential_fetch();
        phase3_first_execute();
        phase4_arithmetic();
        phase5_load_store();
        phase6_branch();
        phase7_jal();

        $display("\n===================================");
        $display("CPU bring-up complete: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("===================================");
        $finish;
    end

endmodule

`default_nettype wire
