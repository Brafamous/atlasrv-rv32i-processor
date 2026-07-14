`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module mem_wb_reg (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             stall,
    input  logic             flush,

    input  logic [XLEN-1:0]  pc_plus4_i,
    input  logic [XLEN-1:0]  alu_result_i,
    input  logic [XLEN-1:0]  load_data_i,
    input  logic [4:0]       rd_addr_i,
    input  control_t         ctrl_i,

    output logic [XLEN-1:0]  pc_plus4_o,
    output logic [XLEN-1:0]  alu_result_o,
    output logic [XLEN-1:0]  load_data_o,
    output logic [4:0]       rd_addr_o,
    output control_t         ctrl_o
);

    always_ff @(posedge clk) begin
        if (!rst_n || flush) begin
            pc_plus4_o   <= '0;
            alu_result_o <= '0;
            load_data_o  <= '0;
            rd_addr_o    <= '0;
            ctrl_o       <= '0;
        end else if (!stall) begin
            pc_plus4_o   <= pc_plus4_i;
            alu_result_o <= alu_result_i;
            load_data_o  <= load_data_i;
            rd_addr_o    <= rd_addr_i;
            ctrl_o       <= ctrl_i;
        end
    end

endmodule

`default_nettype wire
