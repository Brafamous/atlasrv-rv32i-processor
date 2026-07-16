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

    function automatic logic [31:0] enc_b
        (input logic [12:0] imm, input logic [4:0] rs2, rs1,
         input logic [2:0] funct3, input logic [6:0] opcode);
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction

    function automatic logic [31:0] enc_j
        (input logic [20:0] imm, input logic [4:0] rd, input logic [6:0] opcode);
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    function automatic logic [31:0] i_beq (input logic [4:0] rs1, rs2, input logic [12:0] imm);
        i_beq = enc_b(imm, rs2, rs1, 3'b000, OPCODE_BRANCH);
    endfunction

    function automatic logic [31:0] i_bne (input logic [4:0] rs1, rs2, input logic [12:0] imm);
        i_bne = enc_b(imm, rs2, rs1, 3'b001, OPCODE_BRANCH);
    endfunction

    function automatic logic [31:0] i_jal (input logic [4:0] rd, input logic [20:0] imm);
        i_jal = enc_j(imm, rd, OPCODE_JAL);
    endfunction

    function automatic logic [31:0] i_jalr (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_jalr = enc_i(imm, rs1, 3'b000, rd, OPCODE_JALR);
    endfunction

    function automatic logic [31:0] enc_r
        (input logic [6:0] funct7, input logic [4:0] rs2, rs1,
         input logic [2:0] funct3, input logic [4:0] rd, input logic [6:0] opcode);
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] enc_u
        (input logic [19:0] imm20, input logic [4:0] rd, input logic [6:0] opcode);
        enc_u = {imm20, rd, opcode};
    endfunction

    function automatic logic [31:0] i_sub  (input logic [4:0] rd, rs1, rs2);
        i_sub  = enc_r(7'b0100000, rs2, rs1, 3'b000, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_and  (input logic [4:0] rd, rs1, rs2);
        i_and  = enc_r(7'b0000000, rs2, rs1, 3'b111, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_or   (input logic [4:0] rd, rs1, rs2);
        i_or   = enc_r(7'b0000000, rs2, rs1, 3'b110, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_xor  (input logic [4:0] rd, rs1, rs2);
        i_xor  = enc_r(7'b0000000, rs2, rs1, 3'b100, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_slt  (input logic [4:0] rd, rs1, rs2);
        i_slt  = enc_r(7'b0000000, rs2, rs1, 3'b010, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_sltu (input logic [4:0] rd, rs1, rs2);
        i_sltu = enc_r(7'b0000000, rs2, rs1, 3'b011, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_sll  (input logic [4:0] rd, rs1, rs2);
        i_sll  = enc_r(7'b0000000, rs2, rs1, 3'b001, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_srl  (input logic [4:0] rd, rs1, rs2);
        i_srl  = enc_r(7'b0000000, rs2, rs1, 3'b101, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_sra  (input logic [4:0] rd, rs1, rs2);
        i_sra  = enc_r(7'b0100000, rs2, rs1, 3'b101, rd, OPCODE_R_TYPE);
    endfunction

    function automatic logic [31:0] i_lui   (input logic [4:0] rd, input logic [19:0] imm20);
        i_lui   = enc_u(imm20, rd, OPCODE_LUI);
    endfunction
    function automatic logic [31:0] i_auipc (input logic [4:0] rd, input logic [19:0] imm20);
        i_auipc = enc_u(imm20, rd, OPCODE_AUIPC);
    endfunction

    function automatic logic [31:0] i_sb  (input logic [4:0] rs1, rs2, input logic [11:0] imm);
        i_sb  = {imm[11:5], rs2, rs1, 3'b000, imm[4:0], OPCODE_STORE};
    endfunction
    function automatic logic [31:0] i_sh  (input logic [4:0] rs1, rs2, input logic [11:0] imm);
        i_sh  = {imm[11:5], rs2, rs1, 3'b001, imm[4:0], OPCODE_STORE};
    endfunction
    function automatic logic [31:0] i_lb  (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_lb  = enc_i(imm, rs1, 3'b000, rd, OPCODE_LOAD);
    endfunction
    function automatic logic [31:0] i_lbu (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_lbu = enc_i(imm, rs1, 3'b100, rd, OPCODE_LOAD);
    endfunction
    function automatic logic [31:0] i_lh  (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_lh  = enc_i(imm, rs1, 3'b001, rd, OPCODE_LOAD);
    endfunction
    function automatic logic [31:0] i_lhu (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_lhu = enc_i(imm, rs1, 3'b101, rd, OPCODE_LOAD);
    endfunction

    function automatic logic [31:0] nop();
        nop = i_addi(5'd0, 5'd0, 12'd0);
    endfunction

    int cov_branch_taken     = 0;
    int cov_branch_not_taken = 0;
    int cov_jal_seen         = 0;
    int cov_jalr_seen        = 0;
    int cov_flush_events     = 0;

    always @(posedge clk) begin
        if (rst_n && dut.ex_branch_taken) begin
            cov_flush_events = cov_flush_events + 1;
        end
    end

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
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd100));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd42));
        imem.write_word(2, i_sw  (5'd1, 5'd2, 12'd0));
        imem.write_word(3, i_lw  (5'd3, 5'd1, 12'd0));
        imem.write_word(4, i_addi(5'd4, 5'd3, 12'd1));

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
        imem.write_word(4, i_addi(5'd5, 5'd0, 12'd7));

        run_cycles(9);
        check_reg(3, 32'd42, "x3 = mem[100] = 42");
        check_reg(5, 32'd7,  "x5 = 7 (unrelated instruction, no stall needed)");
    endtask

    task automatic phase4_wb_id_gap_of_three();
        $display("\n--- Phase 4: WB->ID Gap-of-3 Dependency (regfile bypass) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd100));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd42));
        imem.write_word(2, i_sw  (5'd1, 5'd2, 12'd0));
        imem.write_word(3, i_lw  (5'd3, 5'd1, 12'd0));

        run_cycles(9);
        check_reg(3, 32'd42, "x3 = mem[100] = 42 (gap-of-3 read of x1 resolved by bypass)");
    endtask

    task automatic phase5_taken_branch();
        $display("\n--- Phase 5: Taken Branch (BEQ) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd1));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd1));
        imem.write_word(2, i_beq (5'd1, 5'd2, 13'sd12));
        imem.write_word(3, i_addi(5'd3, 5'd0, 12'd99));
        imem.write_word(4, i_addi(5'd4, 5'd0, 12'd99));
        imem.write_word(5, i_addi(5'd5, 5'd0, 12'd7));

        run_cycles(10);
        cov_branch_taken = cov_branch_taken + 1;
        check_reg(3, 32'd0, "x3 untouched -- wrong-path instruction after taken branch");
        check_reg(4, 32'd0, "x4 untouched -- wrong-path instruction after taken branch");
        check_reg(5, 32'd7, "x5 = 7 -- landed correctly after taken BEQ");
    endtask

    task automatic phase5_not_taken_branch();
        $display("\n--- Phase 5: Not-Taken Branch (BNE) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd1));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd1));
        imem.write_word(2, i_bne (5'd1, 5'd2, 13'sd12));
        imem.write_word(3, i_addi(5'd3, 5'd0, 12'd5));

        run_cycles(8);
        cov_branch_not_taken = cov_branch_not_taken + 1;
        check_reg(3, 32'd5, "x3 = 5 -- BNE not taken, fell through with no flush");
    endtask

    task automatic phase5_jal();
        $display("\n--- Phase 5: JAL ---");
        apply_reset();
        imem.write_word(0, i_jal (5'd1, 21'sd16));
        imem.write_word(1, i_addi(5'd2, 5'd0, 12'd99));
        imem.write_word(2, i_addi(5'd3, 5'd0, 12'd99));
        imem.write_word(4, i_addi(5'd4, 5'd0, 12'd11));

        run_cycles(8);
        cov_jal_seen = cov_jal_seen + 1;
        check_reg(1, 32'd4,  "jal link = pc+4 = 4");
        check_reg(2, 32'd0,  "x2 untouched -- wrong-path after JAL");
        check_reg(3, 32'd0,  "x3 untouched -- wrong-path after JAL");
        check_reg(4, 32'd11, "x4 = 11 -- landed correctly after JAL");
    endtask

    task automatic phase5_jalr();
        $display("\n--- Phase 5: JALR ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd4, 5'd0, 12'd20));
        imem.write_word(1, i_jalr(5'd5, 5'd4, 12'd4));
        imem.write_word(2, i_addi(5'd6, 5'd0, 12'd99));
        imem.write_word(3, i_addi(5'd7, 5'd0, 12'd99));
        imem.write_word(6, i_addi(5'd8, 5'd0, 12'd13));

        run_cycles(9);
        cov_jalr_seen = cov_jalr_seen + 1;
        check_reg(4, 32'd20, "x4 = 20 (jalr base)");
        check_reg(5, 32'd8,  "jalr link = pc+4 = 8");
        check_reg(6, 32'd0,  "x6 untouched -- wrong-path after JALR");
        check_reg(7, 32'd0,  "x7 untouched -- wrong-path after JALR");
        check_reg(8, 32'd13, "x8 = 13 -- landed correctly after JALR");
    endtask

    task automatic phase6_full_alu_coverage();
        $display("\n--- Phase 6: Full ALU Op Coverage (vs Version 1 ground truth) ---");
        apply_reset();
        imem.write_word(0,  i_addi(5'd1, 5'd0, 12'd12));
        imem.write_word(1,  i_addi(5'd2, 5'd0, 12'd5));
        imem.write_word(2,  i_sub (5'd3, 5'd1, 5'd2));
        imem.write_word(3,  i_and (5'd4, 5'd1, 5'd2));
        imem.write_word(4,  i_or  (5'd5, 5'd1, 5'd2));
        imem.write_word(5,  i_xor (5'd6, 5'd1, 5'd2));
        imem.write_word(6,  i_slt (5'd7, 5'd2, 5'd1));
        imem.write_word(7,  i_sltu(5'd8, 5'd2, 5'd1));
        imem.write_word(8,  i_sll (5'd9, 5'd2, 5'd1));
        imem.write_word(9,  i_srl (5'd10, 5'd1, 5'd2));
        imem.write_word(10, i_sra (5'd11, 5'd1, 5'd2));

        run_cycles(15);
        check_reg(3,  32'd7,   "SUB: x3 = 12-5 = 7");
        check_reg(4,  32'd4,   "AND: x4 = 12&5 = 4");
        check_reg(5,  32'd13,  "OR:  x5 = 12|5 = 13");
        check_reg(6,  32'd9,   "XOR: x6 = 12^5 = 9");
        check_reg(7,  32'd1,   "SLT: x7 = (5<12) = 1");
        check_reg(8,  32'd1,   "SLTU: x8 = (5<12u) = 1");
        check_reg(9,  32'd5 << (12 & 32'h1F),  "SLL: x9 = 5<<(12&0x1F)");
        check_reg(10, 32'd12 >> (5 & 32'h1F),  "SRL: x10 = 12>>(5&0x1F)");
        check_reg(11, 32'd12 >>> (5 & 32'h1F), "SRA: x11 = 12>>>(5&0x1F)");
    endtask

    task automatic phase6_lui_auipc();
        $display("\n--- Phase 6: LUI / AUIPC (vs Version 1 ground truth) ---");
        apply_reset();
        imem.write_word(0, i_lui  (5'd1, 20'h12345));
        imem.write_word(1, i_auipc(5'd2, 20'h00001));

        run_cycles(6);
        check_reg(1, 32'h1234_5000, "LUI: x1 = 0x12345000");
        check_reg(2, 32'h0000_1004, "AUIPC: x2 = pc(4) + 0x1000 = 0x1004");
    endtask

    task automatic phase6_byte_halfword_load_store();
        $display("\n--- Phase 6: Byte/Halfword Load-Store (vs Version 1 ground truth) ---");
        apply_reset();
        imem.write_word(0, i_addi(5'd1, 5'd0, 12'd200));
        imem.write_word(1, i_addi(5'd4, 5'd0, -12'sd1));
        imem.write_word(2, i_sb  (5'd1, 5'd4, 12'd4));
        imem.write_word(3, i_lb  (5'd5, 5'd1, 12'd4));
        imem.write_word(4, i_lbu (5'd6, 5'd1, 12'd4));
        imem.write_word(5, i_sh  (5'd1, 5'd4, 12'd8));
        imem.write_word(6, i_lh  (5'd7, 5'd1, 12'd8));
        imem.write_word(7, i_lhu (5'd8, 5'd1, 12'd8));

        run_cycles(12);
        check_reg(5, 32'hFFFF_FFFF, "LB sign-extends stored 0xFF -> -1");
        check_reg(6, 32'h0000_00FF, "LBU zero-extends stored 0xFF -> 0x000000FF");
        check_reg(7, 32'hFFFF_FFFF, "LH sign-extends stored 0xFFFF -> -1");
        check_reg(8, 32'h0000_FFFF, "LHU zero-extends stored 0xFFFF -> 0x0000FFFF");
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
        phase5_taken_branch();
        phase5_not_taken_branch();
        phase5_jal();
        phase5_jalr();
        phase6_full_alu_coverage();
        phase6_lui_auipc();
        phase6_byte_halfword_load_store();

        $display("\n===================================");
        $display("Pipeline Phase 6: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("Coverage: branch_taken=%0d branch_not_taken=%0d jal=%0d jalr=%0d flush_events=%0d",
                 cov_branch_taken, cov_branch_not_taken, cov_jal_seen, cov_jalr_seen, cov_flush_events);
        $display("===================================");
        $finish;
    end

endmodule

`default_nettype wire
