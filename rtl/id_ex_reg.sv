






























`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module id_ex_reg (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             stall,
    input  logic             flush,

    input  logic [XLEN-1:0]  pc_i,
    input  logic [XLEN-1:0]  pc_plus4_i,
    input  logic [XLEN-1:0]  rs1_data_i,
    input  logic [XLEN-1:0]  rs2_data_i,
    input  logic [4:0]       rs1_addr_i,
    input  logic [4:0]       rs2_addr_i,
    input  logic [4:0]       rd_addr_i,
    input  logic [XLEN-1:0]  immediate_i,
    input  control_t         ctrl_i,

    output logic [XLEN-1:0]  pc_o,
    output logic [XLEN-1:0]  pc_plus4_o,
    output logic [XLEN-1:0]  rs1_data_o,
    output logic [XLEN-1:0]  rs2_data_o,
    output logic [4:0]       rs1_addr_o,
    output logic [4:0]       rs2_addr_o,
    output logic [4:0]       rd_addr_o,
    output logic [XLEN-1:0]  immediate_o,
    output control_t         ctrl_o
);

    always_ff @(posedge clk) begin
        if (!rst_n || flush) begin
            pc_o          <= '0;
            pc_plus4_o    <= '0;
            rs1_data_o    <= '0;
            rs2_data_o    <= '0;
            rs1_addr_o    <= '0;
            rs2_addr_o    <= '0;
            rd_addr_o     <= '0;
            immediate_o   <= '0;
            ctrl_o        <= '0;
        end else if (!stall) begin
            pc_o          <= pc_i;
            pc_plus4_o    <= pc_plus4_i;
            rs1_data_o    <= rs1_data_i;
            rs2_data_o    <= rs2_data_i;
            rs1_addr_o    <= rs1_addr_i;
            rs2_addr_o    <= rs2_addr_i;
            rd_addr_o     <= rd_addr_i;
            immediate_o   <= immediate_i;
            ctrl_o        <= ctrl_i;
        end
    end

endmodule

`default_nettype wire
