`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module ex_stage (
    input  logic [XLEN-1:0]  pc_i,
    input  logic [XLEN-1:0]  pc_plus4_i,
    input  logic [XLEN-1:0]  rs1_data_i,
    input  logic [XLEN-1:0]  rs2_data_i,
    input  logic [4:0]       rd_addr_i,
    input  logic [XLEN-1:0]  immediate_i,
    input  control_t         ctrl_i,

    output logic [XLEN-1:0]  pc_plus4_o,
    output logic [XLEN-1:0]  alu_result_o,
    output logic [XLEN-1:0]  branch_target_o,
    output logic             branch_taken_o,
    output logic [XLEN-1:0]  rs2_data_o,
    output logic [4:0]       rd_addr_o,
    output control_t         ctrl_o
);

    logic [XLEN-1:0] alu_operand_a, alu_operand_b;
    logic [XLEN-1:0] alu_result;
    logic            branch_cond_taken;
    logic [XLEN-1:0] pc_plus_imm;
    logic [XLEN-1:0] jalr_target;

    always_comb begin
        unique case (ctrl_i.alu_src_a)
            ALU_SRC_A_RS1:  alu_operand_a = rs1_data_i;
            ALU_SRC_A_PC:   alu_operand_a = pc_i;
            ALU_SRC_A_ZERO: alu_operand_a = '0;
            default:        alu_operand_a = rs1_data_i;
        endcase
    end

    always_comb begin
        unique case (ctrl_i.alu_src_b)
            ALU_SRC_B_RS2:  alu_operand_b = rs2_data_i;
            ALU_SRC_B_IMM:  alu_operand_b = immediate_i;
            ALU_SRC_B_FOUR: alu_operand_b = 32'd4;
            default:        alu_operand_b = rs2_data_i;
        endcase
    end

    alu u_alu (
        .a_i      (alu_operand_a),
        .b_i      (alu_operand_b),
        .alu_op_i (ctrl_i.alu_op),
        .result_o (alu_result)
    );

    branch_unit u_branch_unit (
        .a_i             (rs1_data_i),
        .b_i             (rs2_data_i),
        .branch_type_i   (ctrl_i.branch_type),
        .branch_taken_o  (branch_cond_taken)
    );

    assign pc_plus_imm = pc_i + immediate_i;
    assign jalr_target  = (alu_result) & ~32'h0000_0001;

    // JALR: jump asserted, operand A came from rs1 -> mask ALU result
    // JAL:  jump asserted, operand A came from PC  -> use dedicated adder, no mask
    // Branch: not a jump, branch_type != BR_NONE   -> use dedicated adder, gated by branch_unit
    assign branch_target_o = (ctrl_i.jump && ctrl_i.alu_src_a == ALU_SRC_A_RS1) ? jalr_target
                                                                                  : pc_plus_imm;

    assign branch_taken_o  = ctrl_i.jump || (ctrl_i.branch_type != BR_NONE && branch_cond_taken);

    assign alu_result_o = alu_result;
    assign pc_plus4_o   = pc_plus4_i;
    assign rs2_data_o   = rs2_data_i;
    assign rd_addr_o    = rd_addr_i;
    assign ctrl_o       = ctrl_i;

endmodule

`default_nettype wire
