`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module phase7_random_regression_tb;

    logic clk;
    logic rst_n;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    logic [XLEN-1:0]    v1_imem_addr;
    logic [INSTR_W-1:0] v1_imem_rdata;
    logic [XLEN-1:0]    v1_dmem_addr, v1_dmem_wdata, v1_dmem_rdata;
    logic [3:0]         v1_dmem_be;
    logic                v1_dmem_we, v1_dmem_re;

    rv32i_single_cycle_core dut_v1 (
        .clk          (clk),
        .rst_n        (rst_n),
        .imem_addr_o  (v1_imem_addr),
        .imem_rdata_i (v1_imem_rdata),
        .dmem_addr_o  (v1_dmem_addr),
        .dmem_wdata_o (v1_dmem_wdata),
        .dmem_be_o    (v1_dmem_be),
        .dmem_we_o    (v1_dmem_we),
        .dmem_re_o    (v1_dmem_re),
        .dmem_rdata_i (v1_dmem_rdata)
    );

    instruction_memory_model #(.MEM_DEPTH_WORDS(64)) v1_imem (
        .addr_i  (v1_imem_addr),
        .instr_o (v1_imem_rdata)
    );

    data_memory_model #(.MEM_DEPTH_BYTES(256)) v1_dmem (
        .clk_i (clk), .addr_i(v1_dmem_addr), .wdata_i(v1_dmem_wdata),
        .be_i(v1_dmem_be), .we_i(v1_dmem_we), .re_i(v1_dmem_re),
        .rdata_o(v1_dmem_rdata)
    );

    logic [XLEN-1:0]    v2_imem_addr;
    logic [INSTR_W-1:0] v2_imem_rdata;
    logic [XLEN-1:0]    v2_dmem_addr, v2_dmem_wdata, v2_dmem_rdata;
    logic [3:0]         v2_dmem_be;
    logic                v2_dmem_we, v2_dmem_re;

    rv32i_pipeline_core dut_v2 (
        .clk          (clk),
        .rst_n        (rst_n),
        .imem_addr_o  (v2_imem_addr),
        .imem_rdata_i (v2_imem_rdata),
        .dmem_addr_o  (v2_dmem_addr),
        .dmem_wdata_o (v2_dmem_wdata),
        .dmem_be_o    (v2_dmem_be),
        .dmem_we_o    (v2_dmem_we),
        .dmem_re_o    (v2_dmem_re),
        .dmem_rdata_i (v2_dmem_rdata)
    );

    instruction_memory_model #(.MEM_DEPTH_WORDS(64)) v2_imem (
        .addr_i  (v2_imem_addr),
        .instr_o (v2_imem_rdata)
    );

    data_memory_model #(.MEM_DEPTH_BYTES(256)) v2_dmem (
        .clk_i (clk), .addr_i(v2_dmem_addr), .wdata_i(v2_dmem_wdata),
        .be_i(v2_dmem_be), .we_i(v2_dmem_we), .re_i(v2_dmem_re),
        .rdata_o(v2_dmem_rdata)
    );

    function automatic logic [31:0] enc_i
        (input logic [11:0] imm, input logic [4:0] rs1,
         input logic [2:0] funct3, input logic [4:0] rd, input logic [6:0] opcode);
        enc_i = {imm, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] enc_r
        (input logic [6:0] funct7, input logic [4:0] rs2, rs1,
         input logic [2:0] funct3, input logic [4:0] rd, input logic [6:0] opcode);
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction

    function automatic logic [31:0] i_addi (input logic [4:0] rd, rs1, input logic [11:0] imm);
        i_addi = enc_i(imm, rs1, 3'b000, rd, OPCODE_I_TYPE);
    endfunction
    function automatic logic [31:0] i_add (input logic [4:0] rd, rs1, rs2);
        i_add = enc_r(7'b0000000, rs2, rs1, 3'b000, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_sub (input logic [4:0] rd, rs1, rs2);
        i_sub = enc_r(7'b0100000, rs2, rs1, 3'b000, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_and (input logic [4:0] rd, rs1, rs2);
        i_and = enc_r(7'b0000000, rs2, rs1, 3'b111, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_or  (input logic [4:0] rd, rs1, rs2);
        i_or  = enc_r(7'b0000000, rs2, rs1, 3'b110, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] i_xor (input logic [4:0] rd, rs1, rs2);
        i_xor = enc_r(7'b0000000, rs2, rs1, 3'b100, rd, OPCODE_R_TYPE);
    endfunction
    function automatic logic [31:0] nop();
        nop = i_addi(5'd0, 5'd0, 12'd0);
    endfunction

    localparam int NUM_INSTRS = 12;
    localparam int REG_POOL   = 8;

    logic [31:0] prog [0:NUM_INSTRS-1];

    task automatic gen_random_program(input int seed_val);
        int k, kind, rd, rs1, rs2;
        int imm;
        for (k = 0; k < NUM_INSTRS; k = k + 1) begin
            kind = $urandom_range(5, 0);
            rd   = $urandom_range(REG_POOL, 1);
            rs1  = $urandom_range(REG_POOL, 0);
            rs2  = $urandom_range(REG_POOL, 0);
            imm  = $urandom_range(400, 0) - 200;

            case (kind)
                0: prog[k] = i_addi(rd[4:0], rs1[4:0], imm[11:0]);
                1: prog[k] = i_add (rd[4:0], rs1[4:0], rs2[4:0]);
                2: prog[k] = i_sub (rd[4:0], rs1[4:0], rs2[4:0]);
                3: prog[k] = i_and (rd[4:0], rs1[4:0], rs2[4:0]);
                4: prog[k] = i_or  (rd[4:0], rs1[4:0], rs2[4:0]);
                5: prog[k] = i_xor (rd[4:0], rs1[4:0], rs2[4:0]);
            endcase
        end
    endtask

    int total_runs      = 0;
    int total_mismatches = 0;

    task automatic run_and_compare(input int run_num);
        int k;
        logic [XLEN-1:0] v1_val, v2_val;
        int mismatches_this_run;

        mismatches_this_run = 0;

        rst_n = 1'b0;
        for (k = 0; k < 64; k = k + 1) begin
            v1_imem.write_word(k, nop());
            v2_imem.write_word(k, nop());
        end
        @(posedge clk); @(posedge clk);
        rst_n = 1'b1;

        for (k = 0; k < NUM_INSTRS; k = k + 1) begin
            v1_imem.write_word(k, prog[k]);
            v2_imem.write_word(k, prog[k]);
        end

        for (k = 0; k < NUM_INSTRS; k = k + 1) @(posedge clk);
        #1;

        for (k = 0; k < NUM_INSTRS + 4; k = k + 1) @(posedge clk);
        #1;

        for (k = 1; k <= REG_POOL; k = k + 1) begin
            v1_val = dut_v1.u_regfile.regs[k];
            v2_val = dut_v2.u_id_stage.u_regfile.regs[k];
            if (v1_val !== v2_val) begin
                $display("MISMATCH run %0d: x%0d  V1=0x%08h  V2=0x%08h", run_num, k, v1_val, v2_val);
                mismatches_this_run = mismatches_this_run + 1;
            end
        end

        total_runs = total_runs + 1;
        if (mismatches_this_run == 0) begin
            $display("PASS: run %0d -- all %0d registers match between V1 and V2", run_num, REG_POOL);
        end else begin
            $display("FAIL: run %0d -- %0d register mismatch(es)", run_num, mismatches_this_run);
            total_mismatches = total_mismatches + mismatches_this_run;
        end
    endtask

    initial begin
        int r;
        rst_n = 1'b0;

        $display("Starting Phase 7 constrained-random regression (V1 vs V2)...");

        for (r = 0; r < 10; r = r + 1) begin
            gen_random_program(1000 + r);
            run_and_compare(r);
        end

        $display("\n===================================");
        $display("Phase 7 regression: %0d runs, %0d total register mismatches", total_runs, total_mismatches);
        if (total_mismatches == 0) begin
            $display("RESULT: PASS -- V2 matches V1 ground truth across all random runs");
        end else begin
            $display("RESULT: FAIL -- see MISMATCH lines above");
        end
        $display("===================================");
        $finish;
    end

endmodule

`default_nettype wire
