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

    //============================================================
    // FETCH: Program Counter and Instruction Interface
    //============================================================

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc_q <= RESET_VECTOR;
        end else begin
            pc_q <= pc_next;
        end
    end

    assign pc_plus4   = pc_q + 32'd4;
    assign pc_next    = pc_plus4;

    assign imem_addr_o = pc_q;
    assign instruction = imem_rdata_i;

    //============================================================
    // DECODE: Instruction Field Extraction
    //============================================================

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];

    //============================================================
    // DECODE: Control and Immediate Generation
    //============================================================

    decoder u_decoder (
        .instr_i (instruction),
        .ctrl_o  (ctrl)
    );

    imm_gen u_imm_gen (
        .instr_i    (instruction),
        .imm_type_i (ctrl.imm_type),
        .imm_o      (immediate)
    );

    //============================================================
    // Temporary defaults for unconnected later milestones
    //============================================================

    assign dmem_addr_o  = '0;
    assign dmem_wdata_o = '0;
    assign dmem_be_o    = '0;
    assign dmem_we_o    = 1'b0;
    assign dmem_re_o    = 1'b0;

endmodule

`default_nettype wire
