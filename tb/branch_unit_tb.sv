`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module branch_unit_tb;

    logic [XLEN-1:0] a;
    logic [XLEN-1:0] b;
    branch_type_e    branch_type;
    logic            branch_taken;

    branch_unit dut (
        .a_i             (a),
        .b_i             (b),
        .branch_type_i   (branch_type),
        .branch_taken_o  (branch_taken)
    );

    task automatic check(
        input branch_type_e    type_val,
        input logic [XLEN-1:0] a_val,
        input logic [XLEN-1:0] b_val,
        input logic            expected,
        input string           test_name
    );
        begin
            branch_type = type_val;
            a           = a_val;
            b           = b_val;
            #1;

            if (branch_taken !== expected) begin
                $display("FAIL: %s", test_name);
                $display("  a            = 0x%08h", a);
                $display("  b            = 0x%08h", b);
                $display("  branch_taken = %0b", branch_taken);
                $display("  expected     = %0b", expected);
                $fatal;
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin
        $display("Starting branch unit directed tests...");

        check(BR_NONE, 32'd5, 32'd5, 1'b0, "BR_NONE never taken");

        check(BR_BEQ,  32'd5, 32'd5, 1'b1, "BEQ taken");
        check(BR_BEQ,  32'd5, 32'd6, 1'b0, "BEQ not taken");

        check(BR_BNE,  32'd5, 32'd6, 1'b1, "BNE taken");
        check(BR_BNE,  32'd5, 32'd5, 1'b0, "BNE not taken");

        check(BR_BLT,  32'hFFFF_FFFF, 32'd1, 1'b1, "BLT signed -1 < 1");
        check(BR_BLT,  32'd5, 32'd1, 1'b0, "BLT signed not taken");

        check(BR_BGE,  32'd5, 32'd1, 1'b1, "BGE signed 5 >= 1");
        check(BR_BGE,  32'hFFFF_FFFF, 32'd1, 1'b0, "BGE signed -1 >= 1 false");

        check(BR_BLTU, 32'd1, 32'hFFFF_FFFF, 1'b1, "BLTU unsigned 1 < max");
        check(BR_BLTU, 32'hFFFF_FFFF, 32'd1, 1'b0, "BLTU unsigned max < 1 false");

        check(BR_BGEU, 32'hFFFF_FFFF, 32'd1, 1'b1, "BGEU unsigned max >= 1");
        check(BR_BGEU, 32'd1, 32'hFFFF_FFFF, 1'b0, "BGEU unsigned 1 >= max false");

        $display("All branch unit tests passed.");
        $finish;
    end

endmodule

`default_nettype wire
