`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module regfile (
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic [REG_ADDR_W-1:0] rs1_addr_i,
    input  logic [REG_ADDR_W-1:0] rs2_addr_i,
    output logic [XLEN-1:0]       rs1_data_o,
    output logic [XLEN-1:0]       rs2_data_o,

    input  logic                  rd_we_i,
    input  logic [REG_ADDR_W-1:0] rd_addr_i,
    input  logic [XLEN-1:0]       rd_data_i
);

    logic [XLEN-1:0] regs [REG_COUNT-1:0];

    integer i;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                regs[i] <= '0;
            end
        end else begin
            if (rd_we_i && (rd_addr_i != '0)) begin
                regs[rd_addr_i] <= rd_data_i;
            end
        end
    end

    // Same-cycle WB->ID bypass: if this cycle's write target matches
    // a read address, the read must return the incoming write value,
    // not the pre-write array contents. Without this, a producer
    // exactly 3 instructions ahead of a consumer (WB coincides with
    // ID) reads a stale value, since the array update from WB's
    // nonblocking assignment isn't visible until the following cycle.
    always_comb begin
        if (rs1_addr_i == '0) begin
            rs1_data_o = '0;
        end else if (rd_we_i && (rd_addr_i != '0) && (rd_addr_i == rs1_addr_i)) begin
            rs1_data_o = rd_data_i;
        end else begin
            rs1_data_o = regs[rs1_addr_i];
        end

        if (rs2_addr_i == '0) begin
            rs2_data_o = '0;
        end else if (rd_we_i && (rd_addr_i != '0) && (rd_addr_i == rs2_addr_i)) begin
            rs2_data_o = rd_data_i;
        end else begin
            rs2_data_o = regs[rs2_addr_i];
        end
    end

endmodule

`default_nettype wire
