`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module rv32i_single_cycle_core (

    input  logic clk,
    input  logic rst_n,

    //============================================================
    // Instruction Memory Interface
    //============================================================

    output logic [XLEN-1:0] imem_addr_o,
    input  logic [INSTR_W-1:0] imem_rdata_i,

    //============================================================
    // Data Memory Interface
    //============================================================

    output logic [XLEN-1:0] dmem_addr_o,
    output logic [XLEN-1:0] dmem_wdata_o,
    output logic [3:0]      dmem_be_o,
    output logic            dmem_we_o,
    output logic            dmem_re_o,

    input  logic [XLEN-1:0] dmem_rdata_i

);

    //============================================================
    // FETCH STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] pc_q;
    logic [XLEN-1:0] pc_next;
    logic [XLEN-1:0] pc_plus4;

    logic [INSTR_W-1:0] instruction;

    //============================================================
    // DECODE STAGE SIGNALS
    //============================================================

    control_t ctrl;

    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
    logic [REG_ADDR_W-1:0] rd_addr;

    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;

    logic [XLEN-1:0] immediate;

    //============================================================
    // EXECUTE STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] alu_operand_a;
    logic [XLEN-1:0] alu_operand_b;

    logic [XLEN-1:0] alu_result;

    logic branch_taken;

    //============================================================
    // MEMORY STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] load_data;

    //============================================================
    // WRITEBACK STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] writeback_data;

endmodule

`default_nettype wire
