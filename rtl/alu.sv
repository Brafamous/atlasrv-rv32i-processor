`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module alu (
    input  logic [XLEN-1:0] a_i,
    input  logic [XLEN-1:0] b_i,
    input  alu_op_e        alu_op_i,
    output logic [XLEN-1:0] result_o
);

    always_comb begin
        unique case (alu_op_i)
            ALU_ADD:    result_o = a_i + b_i;
            ALU_SUB:    result_o = a_i - b_i;
            ALU_SLL:    result_o = a_i << b_i[4:0];
            ALU_SLT:    result_o = ($signed(a_i) < $signed(b_i)) ? 32'd1 : 32'd0;
            ALU_SLTU:   result_o = (a_i < b_i) ? 32'd1 : 32'd0;
            ALU_XOR:    result_o = a_i ^ b_i;
            ALU_SRL:    result_o = a_i >> b_i[4:0];
            ALU_SRA:    result_o = $signed(a_i) >>> b_i[4:0];
            ALU_OR:     result_o = a_i | b_i;
            ALU_AND:    result_o = a_i & b_i;
            ALU_COPY_B: result_o = b_i;
            default:    result_o = '0;
        endcase
    end

endmodule

`default_nettype wire
