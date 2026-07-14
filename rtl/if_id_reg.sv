`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module if_id_reg (
    input  logic                clk,
    input  logic                rst_n,
    input  logic                stall,
    input  logic                flush,

    input  logic [XLEN-1:0]     pc_i,
    input  logic [XLEN-1:0]     pc_plus4_i,
    input  logic [INSTR_W-1:0]  instruction_i,

    output logic [XLEN-1:0]     pc_o,
    output logic [XLEN-1:0]     pc_plus4_o,
    output logic [INSTR_W-1:0]  instruction_o
);

    localparam logic [INSTR_W-1:0] NOP = 32'h0000_0013; // addi x0,x0,0

    always_ff @(posedge clk) begin
        if (!rst_n || flush) begin
            pc_o          <= '0;
            pc_plus4_o    <= '0;
            instruction_o <= NOP;
        end else if (!stall) begin
            pc_o          <= pc_i;
            pc_plus4_o    <= pc_plus4_i;
            instruction_o <= instruction_i;
        end
        // if stall && !flush: hold current values (implicit — no else branch)
    end

endmodule

`default_nettype wire
