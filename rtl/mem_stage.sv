`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module mem_stage (
    input  logic [XLEN-1:0]  pc_plus4_i,
    input  logic [XLEN-1:0]  alu_result_i,
    input  logic [XLEN-1:0]  rs2_data_i,
    input  logic [4:0]       rd_addr_i,
    input  control_t         ctrl_i,

    input  logic [XLEN-1:0]  dmem_rdata_i,

    output logic [XLEN-1:0]  dmem_addr_o,
    output logic [XLEN-1:0]  dmem_wdata_o,
    output logic [3:0]       dmem_be_o,
    output logic             dmem_we_o,
    output logic             dmem_re_o,

    output logic [XLEN-1:0]  pc_plus4_o,
    output logic [XLEN-1:0]  alu_result_o,
    output logic [XLEN-1:0]  load_data_o,
    output logic [4:0]       rd_addr_o,
    output control_t         ctrl_o
);

load_store_unit u_lsu (
        .addr_offset_i (alu_result_i[1:0]),
        .load_type_i   (ctrl_i.load_type),
        .dmem_rdata_i  (dmem_rdata_i),
        .load_data_o   (load_data_o),
        .store_type_i  (ctrl_i.store_type),
        .store_data_i  (rs2_data_i),
        .store_wdata_o (dmem_wdata_o),
        .store_be_o    (dmem_be_o)
    );

    assign dmem_addr_o = alu_result_i;
    assign dmem_we_o   = ctrl_i.mem_write;
    assign dmem_re_o   = ctrl_i.mem_read;

    assign pc_plus4_o   = pc_plus4_i;
    assign alu_result_o = alu_result_i;
    assign rd_addr_o    = rd_addr_i;
    assign ctrl_o       = ctrl_i;

endmodule

`default_nettype wire
