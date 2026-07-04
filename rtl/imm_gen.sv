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
            IMM_I: begin
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
            end

            IMM_S: begin
                imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            end
            default: begin
                imm_o = '0;
            end
        endcase
    end

endmodule

`default_nettype wire
