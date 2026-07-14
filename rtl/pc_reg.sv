`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module pc_reg (
    input  logic             clk,
    input  logic             rst_n,

    input  logic [XLEN-1:0]  pc_next,
    input  logic             pc_en,

    output logic [XLEN-1:0]  pc,
    output logic [XLEN-1:0]  pc_plus4
);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc <= RESET_VECTOR;
        end else if (pc_en) begin
            pc <= pc_next;
        end
    end

    assign pc_plus4 = pc + 32'd4;

endmodule

`default_nettype wire