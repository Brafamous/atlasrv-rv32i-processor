`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module regfile_v1 (
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

    assign rs1_data_o = (rs1_addr_i == '0) ? '0 : regs[rs1_addr_i];
    assign rs2_data_o = (rs2_addr_i == '0) ? '0 : regs[rs2_addr_i];

endmodule

`default_nettype wire
