`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module if_stage (
    input  logic [XLEN-1:0]    pc,
    input  logic [XLEN-1:0]    pc_plus4,
    input  logic [INSTR_W-1:0] imem_rdata_i,

    output logic [XLEN-1:0]    imem_addr_o,
    output logic [XLEN-1:0]    pc_o,
    output logic [XLEN-1:0]    pc_plus4_o,
    output logic [INSTR_W-1:0] instruction_o
);

    assign imem_addr_o  = pc;
    assign pc_o          = pc;
    assign pc_plus4_o    = pc_plus4;
    assign instruction_o = imem_rdata_i;

endmodule

`default_nettype wire
