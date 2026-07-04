`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module imm_gen_tb;

    logic [INSTR_W-1:0] instr;
    imm_type_e          imm_type;
    logic [XLEN-1:0]    imm;

    imm_gen dut (
        .instr_i    (instr),
        .imm_type_i (imm_type),
        .imm_o      (imm)
    );

    task automatic check(
        input logic [INSTR_W-1:0] instr_val,
        input imm_type_e          type_val,
        input logic [XLEN-1:0]    expected,
        input string              test_name
    );
        begin
            instr    = instr_val;
            imm_type = type_val;
            #1;

            if (imm !== expected) begin
                $display("FAIL: %s", test_name);
                $display("  instr    = 0x%08h", instr);
                $display("  imm      = 0x%08h", imm);
                $display("  expected = 0x%08h", expected);
                $fatal;
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin
        $display("Starting immediate generator directed tests...");

        // I-Type positive immediate: imm[11:0] = 12'h00A = +10
        check(32'h00A0_0000, IMM_I, 32'h0000_000A, "I-Type positive immediate");

        // I-Type negative immediate: imm[11:0] = 12'hFFF = -1
        check(32'hFFF0_0000, IMM_I, 32'hFFFF_FFFF, "I-Type negative immediate -1");

        // I-Type negative immediate: imm[11:0] = 12'h800 = -2048
        check(32'h8000_0000, IMM_I, 32'hFFFF_F800, "I-Type minimum negative immediate");

        // S-Type positive immediate: imm[11:0] = 12'h014 = +20
        // imm[11:5] = 7'h00, imm[4:0] = 5'h14
        check(32'h0000_0A00, IMM_S, 32'h0000_0014, "S-Type positive immediate");

        // S-Type negative immediate: imm[11:0] = 12'hFFF = -1
        // imm[11:5] = 7'h7F, imm[4:0] = 5'h1F
        check(32'hFE00_0F80, IMM_S, 32'hFFFF_FFFF, "S-Type negative immediate -1");

        $display("All immediate generator tests passed.");
        $finish;
    end

endmodule

`default_nettype wire
