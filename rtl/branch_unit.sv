`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module branch_unit (
    input  logic [XLEN-1:0] a_i,
    input  logic [XLEN-1:0] b_i,
    input  branch_type_e    branch_type_i,
    output logic            branch_taken_o
);

    always_comb begin
        unique case (branch_type_i)
            BR_BEQ:  branch_taken_o = (a_i == b_i);
            BR_BNE:  branch_taken_o = (a_i != b_i);
            BR_BLT:  branch_taken_o = ($signed(a_i) <  $signed(b_i));
            BR_BGE:  branch_taken_o = ($signed(a_i) >= $signed(b_i));
            BR_BLTU: branch_taken_o = (a_i <  b_i);
            BR_BGEU: branch_taken_o = (a_i >= b_i);
            default: branch_taken_o = 1'b0;
        endcase
    end

endmodule

`default_nettype wire
