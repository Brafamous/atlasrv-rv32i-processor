`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module decoder (
    input  logic [INSTR_W-1:0] instr_i,
    output control_t           ctrl_o
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr_i[6:0];
    assign funct3 = instr_i[14:12];
    assign funct7 = instr_i[31:25];

    always_comb begin
        ctrl_o = '0;

        ctrl_o.alu_op      = ALU_ADD;
        ctrl_o.imm_type    = IMM_I;
        ctrl_o.branch_type = BR_NONE;
        ctrl_o.wb_sel      = WB_ALU;

        unique case (opcode)

            OPCODE_R_TYPE: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.wb_sel    = WB_ALU;

                unique case (funct3)
                    3'b000: ctrl_o.alu_op = (funct7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
                    3'b001: ctrl_o.alu_op = ALU_SLL;
                    3'b010: ctrl_o.alu_op = ALU_SLT;
                    3'b011: ctrl_o.alu_op = ALU_SLTU;
                    3'b100: ctrl_o.alu_op = ALU_XOR;
                    3'b101: ctrl_o.alu_op = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
                    3'b110: ctrl_o.alu_op = ALU_OR;
                    3'b111: ctrl_o.alu_op = ALU_AND;
                    default: ctrl_o.alu_op = ALU_ADD;
                endcase
            end

            OPCODE_I_TYPE: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.imm_type  = IMM_I;
                ctrl_o.wb_sel    = WB_ALU;

                unique case (funct3)
                    3'b000: ctrl_o.alu_op = ALU_ADD;   // ADDI
                    3'b010: ctrl_o.alu_op = ALU_SLT;   // SLTI
                    3'b011: ctrl_o.alu_op = ALU_SLTU;  // SLTIU
                    3'b100: ctrl_o.alu_op = ALU_XOR;   // XORI
                    3'b110: ctrl_o.alu_op = ALU_OR;    // ORI
                    3'b111: ctrl_o.alu_op = ALU_AND;   // ANDI
                    3'b001: ctrl_o.alu_op = ALU_SLL;   // SLLI
                    3'b101: ctrl_o.alu_op = (funct7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
                    default: ctrl_o.alu_op = ALU_ADD;
                endcase
            end

            OPCODE_LOAD: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.mem_read  = 1'b1;
                ctrl_o.imm_type  = IMM_I;
                ctrl_o.alu_op    = ALU_ADD;
                ctrl_o.wb_sel    = WB_MEM;
            end

            OPCODE_STORE: begin
                ctrl_o.mem_write = 1'b1;
                ctrl_o.imm_type  = IMM_S;
                ctrl_o.alu_op    = ALU_ADD;
            end

            OPCODE_BRANCH: begin
                ctrl_o.imm_type = IMM_B;
                ctrl_o.alu_op   = ALU_SUB;

                unique case (funct3)
                    3'b000: ctrl_o.branch_type = BR_BEQ;
                    3'b001: ctrl_o.branch_type = BR_BNE;
                    3'b100: ctrl_o.branch_type = BR_BLT;
                    3'b101: ctrl_o.branch_type = BR_BGE;
                    3'b110: ctrl_o.branch_type = BR_BLTU;
                    3'b111: ctrl_o.branch_type = BR_BGEU;
                    default: ctrl_o.branch_type = BR_NONE;
                endcase
            end

            OPCODE_JAL: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.jump      = 1'b1;
                ctrl_o.imm_type  = IMM_J;
                ctrl_o.wb_sel    = WB_PC4;
            end

            OPCODE_JALR: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.jump      = 1'b1;
                ctrl_o.imm_type  = IMM_I;
                ctrl_o.alu_op    = ALU_ADD;
                ctrl_o.wb_sel    = WB_PC4;
            end

            OPCODE_LUI: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.imm_type  = IMM_U;
                ctrl_o.alu_op    = ALU_COPY_B;
                ctrl_o.wb_sel    = WB_ALU;
            end

            OPCODE_AUIPC: begin
                ctrl_o.reg_write = 1'b1;
                ctrl_o.imm_type  = IMM_U;
                ctrl_o.alu_op    = ALU_ADD;
                ctrl_o.wb_sel    = WB_ALU;
            end

            default: begin
                ctrl_o = '0;
                ctrl_o.alu_op      = ALU_ADD;
                ctrl_o.imm_type    = IMM_I;
                ctrl_o.branch_type = BR_NONE;
                ctrl_o.wb_sel      = WB_ALU;
            end

        endcase
    end

endmodule

`default_nettype wire

