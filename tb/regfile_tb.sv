`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module regfile_tb;

    logic clk;
    logic rst_n;

    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
    logic [XLEN-1:0]       rs1_data;
    logic [XLEN-1:0]       rs2_data;

    logic                  rd_we;
    logic [REG_ADDR_W-1:0] rd_addr;
    logic [XLEN-1:0]       rd_data;

    regfile dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .rs1_addr_i (rs1_addr),
        .rs2_addr_i (rs2_addr),
        .rs1_data_o (rs1_data),
        .rs2_data_o (rs2_data),
        .rd_we_i    (rd_we),
        .rd_addr_i  (rd_addr),
        .rd_data_i  (rd_data)
    );

    always #5 clk = ~clk;

    task automatic check_read(
        input logic [REG_ADDR_W-1:0] addr1,
        input logic [REG_ADDR_W-1:0] addr2,
        input logic [XLEN-1:0]       exp1,
        input logic [XLEN-1:0]       exp2,
        input string                 test_name
    );
        begin
            rs1_addr = addr1;
            rs2_addr = addr2;
            #1;

            if ((rs1_data !== exp1) || (rs2_data !== exp2)) begin
                $display("FAIL: %s", test_name);
                $display("  rs1_addr = %0d, rs1_data = 0x%08h, expected = 0x%08h", addr1, rs1_data, exp1);
                $display("  rs2_addr = %0d, rs2_data = 0x%08h, expected = 0x%08h", addr2, rs2_data, exp2);
                $fatal;
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    task automatic write_reg(
        input logic [REG_ADDR_W-1:0] addr,
        input logic [XLEN-1:0]       data
    );
        begin
            rd_we   = 1'b1;
            rd_addr = addr;
            rd_data = data;
            @(posedge clk);
            #1;
            rd_we   = 1'b0;
            rd_addr = '0;
            rd_data = '0;
        end
    endtask

    initial begin
        $display("Starting register file directed tests...");

        clk       = 1'b0;
        rst_n     = 1'b0;
        rs1_addr  = '0;
        rs2_addr  = '0;
        rd_we     = 1'b0;
        rd_addr   = '0;
        rd_data   = '0;

        repeat (2) @(posedge clk);
        rst_n = 1'b1;
        #1;

        check_read(5'd1, 5'd2, 32'h0000_0000, 32'h0000_0000, "Reset clears registers");

        write_reg(5'd1, 32'h1111_1111);
        write_reg(5'd2, 32'h2222_2222);
        check_read(5'd1, 5'd2, 32'h1111_1111, 32'h2222_2222, "Write/read x1 and x2");

        write_reg(5'd0, 32'hDEAD_BEEF);
        check_read(5'd0, 5'd1, 32'h0000_0000, 32'h1111_1111, "x0 ignores writes and reads zero");

        write_reg(5'd31, 32'hFFFF_1234);
        check_read(5'd31, 5'd2, 32'hFFFF_1234, 32'h2222_2222, "Dual read ports work");

        rd_we   = 1'b0;
        rd_addr = 5'd3;
        rd_data = 32'h3333_3333;
        @(posedge clk);
        #1;
        check_read(5'd3, 5'd0, 32'h0000_0000, 32'h0000_0000, "Write disabled prevents register update");

        $display("All register file tests passed.");
        $finish;
    end

endmodule

`default_nettype wire
