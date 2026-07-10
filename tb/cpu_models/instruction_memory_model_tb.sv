`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module instruction_memory_model_tb;

    localparam int DEPTH = 8; // small depth so out-of-range addresses are easy to reach

    logic [XLEN-1:0]    addr;
    logic [INSTR_W-1:0] instr;

    int pass_count = 0;
    int fail_count = 0;

    instruction_memory_model #(
        .MEM_DEPTH_WORDS (DEPTH)
    ) dut (
        .addr_i  (addr),
        .instr_o (instr)
    );

    localparam logic [INSTR_W-1:0] NOP = 32'h0000_0013;

    task automatic check(input logic [INSTR_W-1:0] expected, input string name);
        if (instr !== expected) begin
            $display("FAIL: %s -- instr = 0x%08h, expected 0x%08h", name, instr, expected);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: %s -- instr = 0x%08h", name, instr);
            pass_count = pass_count + 1;
        end
    endtask

    initial begin
        // --- Default contents: every word should read back as NOP ---
        addr = 32'd0;  #1; check(NOP, "word 0 defaults to NOP");
        addr = 32'd4;  #1; check(NOP, "word 1 defaults to NOP");
        addr = 32'd28; #1; check(NOP, "word 7 (last valid word) defaults to NOP");

        // --- Valid write, valid read back ---
        dut.write_word(0, 32'h00500093); // addi x1,x0,5
        addr = 32'd0; #1;
        check(32'h00500093, "word 0 reads back written instruction");

        dut.write_word(3, 32'hDEAD0033); // arbitrary bit pattern, not required to be a legal instruction
        addr = 32'd12; #1; // byte address 12 -> word index 3
        check(32'hDEAD0033, "word 3 reads back written pattern");

        addr = 32'd4; #1;
        check(NOP, "untouched word 1 is still NOP after unrelated writes");

        // --- Out-of-range read ---
        addr = 32'd1000; #1; // far beyond DEPTH*4 = 32
        check(NOP, "out-of-range read returns NOP");

        $display("\n-----------------------------------");
        $display("Directed checks: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("-----------------------------------\n");

        if (fail_count > 0) begin
            $display("Skipping out-of-range write check due to earlier failures.");
            $finish;
        end

        // --- Out-of-range write ---
        // Expected to terminate simulation via $fatal. If execution
        // reaches the $display below instead, this check has FAILED --
        // the bounds check in write_word() did not fire.
        $display("Attempting out-of-range write_word() -- expecting $fatal below:");
        dut.write_word(DEPTH, 32'hFFFF_FFFF); // index == DEPTH is one past the last valid index

        $display("FAIL: out-of-range write_word() did not trigger $fatal");
        $finish;
    end

endmodule

`default_nettype wire
