`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module data_memory_model_tb;

    localparam int DEPTH = 32;

    logic        clk;
    logic [XLEN-1:0] addr;
    logic [XLEN-1:0] wdata;
    logic [3:0]      be;
    logic            we;
    logic            re;
    logic [XLEN-1:0] rdata;

    int pass_count = 0;
    int fail_count = 0;

    initial clk = 1'b0;
    always #5 clk = ~clk;

    data_memory_model #(
        .MEM_DEPTH_BYTES (DEPTH)
    ) dut (
        .clk_i   (clk),
        .addr_i  (addr),
        .wdata_i (wdata),
        .be_i    (be),
        .we_i    (we),
        .re_i    (re),
        .rdata_o (rdata)
    );

    task automatic check(input logic [XLEN-1:0] expected, input string name);
        if (rdata !== expected) begin
            $display("FAIL: %s -- rdata = 0x%08h, expected 0x%08h", name, rdata, expected);
            fail_count = fail_count + 1;
        end else begin
            $display("PASS: %s -- rdata = 0x%08h", name, rdata);
            pass_count = pass_count + 1;
        end
    endtask

    task automatic seed_word(input logic [XLEN-1:0] a, input logic [XLEN-1:0] val);
        addr = a; wdata = val; be = 4'b1111; we = 1'b1; re = 1'b0;
        @(posedge clk); #1;
        we = 1'b0;
    endtask

    task automatic partial_write(input logic [XLEN-1:0] a, input logic [XLEN-1:0] val, input logic [3:0] mask);
        addr = a; wdata = val; be = mask; we = 1'b1; re = 1'b0;
        @(posedge clk); #1;
        we = 1'b0;
    endtask

    task automatic read_check(input logic [XLEN-1:0] a, input logic [XLEN-1:0] expected, input string name);
        addr = a; re = 1'b1;
        #1; check(expected, name);
    endtask

    initial begin
        we = 1'b0; re = 1'b0; addr = '0; wdata = '0; be = 4'b0000;
        @(posedge clk); #1;

        addr = 32'd0; re = 1'b0;
        #1; check(32'h0000_0000, "re_i=0 forces rdata to zero");

        seed_word(32'd0, 32'hAABBCCDD);
        read_check(32'd0, 32'hAABBCCDD, "re_i=1 reads back full-word write");

        seed_word(32'd4, 32'hAABBCCDD);
        partial_write(32'd4, 32'h0000_0011, 4'b0001);
        read_check(32'd4, 32'hAABBCC11, "byte0 write updates lane0 only");

        seed_word(32'd8, 32'hAABBCCDD);
        partial_write(32'd8, 32'h0000_2200, 4'b0010);
        read_check(32'd8, 32'hAABB22DD, "byte1 write updates lane1 only");

        seed_word(32'd12, 32'hAABBCCDD);
        partial_write(32'd12, 32'h0033_0000, 4'b0100);
        read_check(32'd12, 32'hAA33CCDD, "byte2 write updates lane2 only");

        seed_word(32'd16, 32'hAABBCCDD);
        partial_write(32'd16, 32'h4400_0000, 4'b1000);
        read_check(32'd16, 32'h44BBCCDD, "byte3 write updates lane3 only");

        seed_word(32'd20, 32'hAABBCCDD);
        partial_write(32'd20, 32'h0000_5566, 4'b0011);
        read_check(32'd20, 32'hAABB5566, "lower halfword write (SH low)");

        seed_word(32'd24, 32'hAABBCCDD);
        partial_write(32'd24, 32'h7788_0000, 4'b1100);
        read_check(32'd24, 32'h7788CCDD, "upper halfword write (SH high)");

        seed_word(32'd28, 32'h1111_1111);
        read_check(32'd28, 32'h1111_1111, "seed value confirmed before simultaneous test");

        addr = 32'd28; wdata = 32'h2222_2222; be = 4'b1111; we = 1'b1; re = 1'b1;
        #1; check(32'h1111_1111, "read-old-data: rdata shows old value before the edge");
        @(posedge clk); #1;
        we = 1'b0;
        #1; check(32'h2222_2222, "after the edge, read reflects the new write");

        $display("\n-----------------------------------");
        $display("Directed checks: %0d PASS, %0d FAIL", pass_count, fail_count);
        $display("-----------------------------------\n");

        if (fail_count > 0) begin
            $display("Skipping out-of-range write check due to earlier failures.");
            $finish;
        end

        we = 1'b0; re = 1'b0;
        addr = 32'd1000; wdata = 32'hDEAD_BEEF; be = 4'b1111;
        $display("Attempting out-of-range write -- expecting $fatal below:");
        we = 1'b1;
        @(posedge clk); #1;

        we = 1'b0;
        $display("FAIL: out-of-range write did not trigger $fatal");
        $finish;
    end

endmodule

`default_nettype wire