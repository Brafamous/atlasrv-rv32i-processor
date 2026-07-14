`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module id_stage (
    input  logic clk,
    input  logic rst_n,

    input  logic [XLEN-1:0]    pc_i,
    input  logic [XLEN-1:0]    pc_plus4_i,
    input  logic [INSTR_W-1:0] instruction_i,

    // Regfile write port, driven by WB stage
    input  logic [4:0]         wb_rd_addr_i,
    input  logic [XLEN-1:0]    wb_wdata_i,
    input  logic                wb_reg_write_i,

    output logic [XLEN-1:0]    pc_o,
    output logic [XLEN-1:0]    pc_plus4_o,
    output logic [XLEN-1:0]    rs1_data_o,
    output logic [XLEN-1:0]    rs2_data_o,
    output logic [4:0]         rs1_addr_o,
    output logic [4:0]         rs2_addr_o,
    output logic [4:0]         rd_addr_o,
    output logic [XLEN-1:0]    immediate_o,
    output control_t           ctrl_o
);

    logic [4:0] rs1_addr, rs2_addr, rd_addr;

    assign rs1_addr = instruction_i[19:15];
    assign rs2_addr = instruction_i[24:20];
    assign rd_addr  = instruction_i[11:7];

    decoder u_decoder (
        .instr_i (instruction_i),
        .ctrl_o  (ctrl_o)
    );
    regfile u_regfile (
            .clk        (clk),
            .rst_n      (rst_n),
            .rs1_addr_i (rs1_addr),
            .rs2_addr_i (rs2_addr),
            .rs1_data_o (rs1_data_o),
            .rs2_data_o (rs2_data_o),
            .rd_we_i    (wb_reg_write_i),
            .rd_addr_i  (wb_rd_addr_i),
            .rd_data_i  (wb_wdata_i)
        );

    imm_gen u_imm_gen (
        .instr_i    (instruction_i),
        .imm_type_i (ctrl_o.imm_type),
        .imm_o      (immediate_o)
    );

    assign pc_o        = pc_i;
    assign pc_plus4_o  = pc_plus4_i;
    assign rs1_addr_o  = rs1_addr;
    assign rs2_addr_o  = rs2_addr;
    assign rd_addr_o   = rd_addr;

endmodule

`default_nettype wire
