`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module rv32i_pipeline_core (
    input  logic clk,
    input  logic rst_n,

    output logic [XLEN-1:0]    imem_addr_o,
    input  logic [INSTR_W-1:0] imem_rdata_i,

    output logic [XLEN-1:0]    dmem_addr_o,
    output logic [XLEN-1:0]    dmem_wdata_o,
    output logic [3:0]         dmem_be_o,
    output logic                dmem_we_o,
    output logic                dmem_re_o,
    input  logic [XLEN-1:0]    dmem_rdata_i
);

    // ----------------------------------------------------------
    // Phase 1 locked constants: no hazards, no forwarding
    // ----------------------------------------------------------
    logic stall;
    logic flush;
    assign stall = 1'b0;
    assign flush = 1'b0;

    // ----------------------------------------------------------
    // PC
    // ----------------------------------------------------------
    logic [XLEN-1:0] pc, pc_plus4;
    logic [XLEN-1:0] pc_next;
    assign pc_next = pc_plus4; // Phase 1: always sequential

    pc_reg u_pc_reg (
        .clk      (clk),
        .rst_n    (rst_n),
        .pc_next  (pc_next),
        .pc_en    (1'b1),
        .pc       (pc),
        .pc_plus4 (pc_plus4)
    );

    // ----------------------------------------------------------
    // IF
    // ----------------------------------------------------------
    logic [XLEN-1:0]    if_pc, if_pc_plus4;
    logic [INSTR_W-1:0] if_instruction;

    if_stage u_if_stage (
        .pc            (pc),
        .pc_plus4      (pc_plus4),
        .imem_rdata_i  (imem_rdata_i),
        .imem_addr_o   (imem_addr_o),
        .pc_o          (if_pc),
        .pc_plus4_o    (if_pc_plus4),
        .instruction_o (if_instruction)
    );

    // ----------------------------------------------------------
    // IF/ID
    // ----------------------------------------------------------
    logic [XLEN-1:0]    idreg_pc, idreg_pc_plus4;
    logic [INSTR_W-1:0] idreg_instruction;

    if_id_reg u_if_id_reg (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall         (stall),
        .flush         (flush),
        .pc_i          (if_pc),
        .pc_plus4_i    (if_pc_plus4),
        .instruction_i (if_instruction),
        .pc_o          (idreg_pc),
        .pc_plus4_o    (idreg_pc_plus4),
        .instruction_o (idreg_instruction)
    );

    // ----------------------------------------------------------
    // ID
    // ----------------------------------------------------------
    logic [XLEN-1:0] id_pc, id_pc_plus4;
    logic [XLEN-1:0] id_rs1_data, id_rs2_data;
    logic [4:0]      id_rs1_addr, id_rs2_addr, id_rd_addr;
    logic [XLEN-1:0] id_immediate;
    control_t        id_ctrl;

    // Backward connection: WB -> ID regfile write port
    logic [4:0]      wb_rd_addr;
    logic [XLEN-1:0] wb_wdata;
    logic            wb_reg_write;

    id_stage u_id_stage (
        .clk            (clk),
        .rst_n          (rst_n),
        .pc_i           (idreg_pc),
        .pc_plus4_i     (idreg_pc_plus4),
        .instruction_i  (idreg_instruction),
        .wb_rd_addr_i   (wb_rd_addr),
        .wb_wdata_i     (wb_wdata),
        .wb_reg_write_i (wb_reg_write),
        .pc_o           (id_pc),
        .pc_plus4_o     (id_pc_plus4),
        .rs1_data_o     (id_rs1_data),
        .rs2_data_o     (id_rs2_data),
        .rs1_addr_o     (id_rs1_addr),
        .rs2_addr_o     (id_rs2_addr),
        .rd_addr_o      (id_rd_addr),
        .immediate_o    (id_immediate),
        .ctrl_o         (id_ctrl)
    );

    // ----------------------------------------------------------
    // ID/EX
    // ----------------------------------------------------------
    logic [XLEN-1:0] exreg_pc, exreg_pc_plus4;
    logic [XLEN-1:0] exreg_rs1_data, exreg_rs2_data;
    logic [4:0]      exreg_rs1_addr, exreg_rs2_addr, exreg_rd_addr;
    logic [XLEN-1:0] exreg_immediate;
    control_t        exreg_ctrl;

    id_ex_reg u_id_ex_reg (
        .clk         (clk),
        .rst_n       (rst_n),
        .stall       (stall),
        .flush       (flush),
        .pc_i        (id_pc),
        .pc_plus4_i  (id_pc_plus4),
        .rs1_data_i  (id_rs1_data),
        .rs2_data_i  (id_rs2_data),
        .rs1_addr_i  (id_rs1_addr),
        .rs2_addr_i  (id_rs2_addr),
        .rd_addr_i   (id_rd_addr),
        .immediate_i (id_immediate),
        .ctrl_i      (id_ctrl),
        .pc_o        (exreg_pc),
        .pc_plus4_o  (exreg_pc_plus4),
        .rs1_data_o  (exreg_rs1_data),
        .rs2_data_o  (exreg_rs2_data),
        .rs1_addr_o  (exreg_rs1_addr),
        .rs2_addr_o  (exreg_rs2_addr),
        .rd_addr_o   (exreg_rd_addr),
        .immediate_o (exreg_immediate),
        .ctrl_o      (exreg_ctrl)
    );

    // ----------------------------------------------------------
    // EX
    // ----------------------------------------------------------
    logic [XLEN-1:0] ex_pc_plus4;
    logic [XLEN-1:0] ex_alu_result;
    logic [XLEN-1:0] ex_branch_target;
    logic            ex_branch_taken;
    logic [XLEN-1:0] ex_rs2_data;
    logic [4:0]      ex_rd_addr;
    control_t        ex_ctrl;

    ex_stage u_ex_stage (
        .pc_i             (exreg_pc),
        .pc_plus4_i       (exreg_pc_plus4),
        .rs1_data_i       (exreg_rs1_data),
        .rs2_data_i       (exreg_rs2_data),
        .rd_addr_i        (exreg_rd_addr),
        .immediate_i      (exreg_immediate),
        .ctrl_i           (exreg_ctrl),
        .pc_plus4_o       (ex_pc_plus4),
        .alu_result_o     (ex_alu_result),
        .branch_target_o  (ex_branch_target),
        .branch_taken_o   (ex_branch_taken),
        .rs2_data_o       (ex_rs2_data),
        .rd_addr_o        (ex_rd_addr),
        .ctrl_o           (ex_ctrl)
    );

    // ----------------------------------------------------------
    // EX/MEM
    // ----------------------------------------------------------
    logic [XLEN-1:0] memreg_pc_plus4;
    logic [XLEN-1:0] memreg_alu_result;
    logic [XLEN-1:0] memreg_branch_target;
    logic            memreg_branch_taken;
    logic [XLEN-1:0] memreg_rs2_data;
    logic [4:0]      memreg_rd_addr;
    control_t        memreg_ctrl;

    ex_mem_reg u_ex_mem_reg (
        .clk              (clk),
        .rst_n            (rst_n),
        .stall            (stall),
        .flush            (flush),
        .pc_plus4_i       (ex_pc_plus4),
        .alu_result_i     (ex_alu_result),
        .branch_target_i  (ex_branch_target),
        .branch_taken_i   (ex_branch_taken),
        .rs2_data_i       (ex_rs2_data),
        .rd_addr_i        (ex_rd_addr),
        .ctrl_i           (ex_ctrl),
        .pc_plus4_o       (memreg_pc_plus4),
        .alu_result_o     (memreg_alu_result),
        .branch_target_o  (memreg_branch_target),
        .branch_taken_o   (memreg_branch_taken),
        .rs2_data_o       (memreg_rs2_data),
        .rd_addr_o        (memreg_rd_addr),
        .ctrl_o           (memreg_ctrl)
    );

    // ----------------------------------------------------------
    // MEM
    // ----------------------------------------------------------
    logic [XLEN-1:0] mem_pc_plus4;
    logic [XLEN-1:0] mem_alu_result;
    logic [XLEN-1:0] mem_load_data;
    logic [4:0]      mem_rd_addr;
    control_t        mem_ctrl;

    mem_stage u_mem_stage (
        .pc_plus4_i    (memreg_pc_plus4),
        .alu_result_i  (memreg_alu_result),
        .rs2_data_i    (memreg_rs2_data),
        .rd_addr_i     (memreg_rd_addr),
        .ctrl_i        (memreg_ctrl),
        .dmem_rdata_i  (dmem_rdata_i),
        .dmem_addr_o   (dmem_addr_o),
        .dmem_wdata_o  (dmem_wdata_o),
        .dmem_be_o     (dmem_be_o),
        .dmem_we_o     (dmem_we_o),
        .dmem_re_o     (dmem_re_o),
        .pc_plus4_o    (mem_pc_plus4),
        .alu_result_o  (mem_alu_result),
        .load_data_o   (mem_load_data),
        .rd_addr_o     (mem_rd_addr),
        .ctrl_o        (mem_ctrl)
    );

    // ----------------------------------------------------------
    // MEM/WB
    // ----------------------------------------------------------
    logic [XLEN-1:0] wbreg_pc_plus4;
    logic [XLEN-1:0] wbreg_alu_result;
    logic [XLEN-1:0] wbreg_load_data;
    logic [4:0]      wbreg_rd_addr;
    control_t        wbreg_ctrl;

    mem_wb_reg u_mem_wb_reg (
        .clk           (clk),
        .rst_n         (rst_n),
        .stall         (stall),
        .flush         (flush),
        .pc_plus4_i    (mem_pc_plus4),
        .alu_result_i  (mem_alu_result),
        .load_data_i   (mem_load_data),
        .rd_addr_i     (mem_rd_addr),
        .ctrl_i        (mem_ctrl),
        .pc_plus4_o    (wbreg_pc_plus4),
        .alu_result_o  (wbreg_alu_result),
        .load_data_o   (wbreg_load_data),
        .rd_addr_o     (wbreg_rd_addr),
        .ctrl_o        (wbreg_ctrl)
    );

    // ----------------------------------------------------------
    // WB
    // ----------------------------------------------------------
    wb_stage u_wb_stage (
        .alu_result_i (wbreg_alu_result),
        .load_data_i  (wbreg_load_data),
        .pc_plus4_i   (wbreg_pc_plus4),
        .rd_addr_i    (wbreg_rd_addr),
        .ctrl_i       (wbreg_ctrl),
        .rd_addr_o    (wb_rd_addr),
        .wdata_o      (wb_wdata),
        .reg_write_o  (wb_reg_write)
    );

endmodule

`default_nettype wire
