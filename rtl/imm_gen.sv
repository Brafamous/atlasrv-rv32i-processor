`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module imm_gen (
    input  logic [INSTR_W-1:0] instr_i,
    input  imm_type_e          imm_type_i,
    output logic [XLEN-1:0]    imm_o
);

    always_comb begin
        unique case (imm_type_i)

            // I-Type: ADDI, loads, JALR
            // imm[11:0] = instr[31:20]
            IMM_I: begin
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
            end

            // S-Type: stores
            // imm[11:5] = instr[31:25]
            // imm[4:0]  = instr[11:7]
            IMM_S: begin
                imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            end

            // B-Type: branches
            // imm[12]   = instr[31]
            // imm[10:5] = instr[30:25]
            // imm[4:1]  = instr[11:8]
            // imm[11]   = instr[7]
            // imm[0]    = 1'b0
            IMM_B: begin
                imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7],
                         instr_i[30:25], instr_i[11:8], 1'b0};
            end

            // U-Type: LUI, AUIPC
            // imm[31:12] = instr[31:12]
            // imm[11:0]  = 12'b0
            IMM_U: begin
                imm_o = {instr_i[31:12], 12'b0};
            end

            // J-Type: JAL
            // imm[20]    = instr[31]
            // imm[10:1]  = instr[30:21]
            // imm[11]    = instr[20]
            // imm[19:12] = instr[19:12]
            // imm[0]     = 1'b0
            IMM_J: begin
                imm_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12],
                         instr_i[20], instr_i[30:21], 1'b0};
            end

            default: begin
                imm_o = '0;
            end

        endcase
    end

endmodule

`default_nettype wire