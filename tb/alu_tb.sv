`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module alu_tb;

    logic [XLEN-1:0] a;
    logic [XLEN-1:0] b;
    alu_op_e        alu_op;
    logic [XLEN-1:0] result;

    alu dut (
        .a_i      (a),
        .b_i      (b),
        .alu_op_i (alu_op),
        .result_o (result)
    );

    task automatic check(
        input alu_op_e        op,
        input logic [XLEN-1:0] a_val,
        input logic [XLEN-1:0] b_val,
        input logic [XLEN-1:0] expected,
        input string           test_name
    );
        begin
            alu_op = op;
            a      = a_val;
            b      = b_val;
            #1;

            if (result !== expected) begin
                $display("FAIL: %s", test_name);
                $display("  a        = 0x%08h", a);
                $display("  b        = 0x%08h", b);
                $display("  result   = 0x%08h", result);
                $display("  expected = 0x%08h", expected);
                $fatal;
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin
        $display("Starting ALU directed tests...");

        check(ALU_ADD,    32'd10,       32'd5,        32'd15,       "ADD basic");
        check(ALU_SUB,    32'd10,       32'd5,        32'd5,        "SUB basic");
        check(ALU_SLL,    32'h0000_0001,32'd4,        32'h0000_0010,"SLL basic");
        check(ALU_SLT,    32'hFFFF_FFFF,32'd1,        32'd1,        "SLT signed negative less than positive");
        check(ALU_SLT,    32'd5,        32'd1,        32'd0,        "SLT signed false");
        check(ALU_SLTU,   32'hFFFF_FFFF,32'd1,        32'd0,        "SLTU unsigned false");
        check(ALU_XOR,    32'hAAAA_5555,32'hFFFF_0000,32'h5555_5555,"XOR basic");
        check(ALU_SRL,    32'h8000_0000,32'd4,        32'h0800_0000,"SRL logical shift");
        check(ALU_SRA,    32'h8000_0000,32'd4,        32'hF800_0000,"SRA arithmetic shift");
        check(ALU_OR,     32'hAAAA_0000,32'h0000_5555,32'hAAAA_5555,"OR basic");
        check(ALU_AND,    32'hAAAA_5555,32'hFFFF_0000,32'hAAAA_0000,"AND basic");
        check(ALU_COPY_B, 32'h1234_5678,32'hDEAD_BEEF,32'hDEAD_BEEF,"COPY_B basic");

        $display("All ALU tests passed.");
        $finish;
    end

endmodule

`default_nettype wire
