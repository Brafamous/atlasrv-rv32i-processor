`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module ex_mem_reg (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             stall,
    input  logic             flush,

    input  logic [XLEN-1:0]  pc_plus4_i,
    input  logic [XLEN-1:0]  alu_result_i,
    input  logic [XLEN-1:0]  branch_target_i,
    input  logic             branch_taken_i,
    input  logic [XLEN-1:0]  rs2_data_i,
    input  logic [4:0]       rd_addr_i,
    input  control_t         ctrl_i,

    output logic [XLEN-1:0]  pc_plus4_o,
    output logic [XLEN-1:0]  alu_result_o,
    output logic [XLEN-1:0]  branch_target_o,
    output logic             branch_taken_o,
    output logic [XLEN-1:0]  rs2_data_o,
    output logic [4:0]       rd_addr_o,
    output control_t         ctrl_o
);

    always_ff @(posedge clk) begin
        if (!rst_n || flush) begin
            pc_plus4_o      <= '0;
            alu_result_o    <= '0;
            branch_target_o <= '0;
            branch_taken_o  <= 1'b0;
            rs2_data_o      <= '0;
            rd_addr_o       <= '0;
            ctrl_o          <= '0;
        end else if (!stall) begin
            pc_plus4_o      <= pc_plus4_i;
            alu_result_o    <= alu_result_i;
            branch_target_o <= branch_target_i;
            branch_taken_o  <= branch_taken_i;
            rs2_data_o      <= rs2_data_i;
            rd_addr_o       <= rd_addr_i;
            ctrl_o          <= ctrl_i;
        end
    end

endmodule

`default_nettype wire
