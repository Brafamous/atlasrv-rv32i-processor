`timescale 1ns/1ps
`default_nettype none

package rv32i_pkg;

    // ------------------------------------------------------------
    // Core architectural parameters
    // ------------------------------------------------------------

    parameter int XLEN       = 32;
    parameter int INSTR_W    = 32;
    parameter int REG_COUNT  = 32;
    parameter int REG_ADDR_W = 5;

    parameter logic [XLEN-1:0] RESET_VECTOR = 32'h0000_0000;

    // ------------------------------------------------------------
    // ALU operation encoding
    // ------------------------------------------------------------
    // This enum defines the shared ALU operation vocabulary used
    // by the decoder, ALU, and later verification components.

    typedef enum logic [3:0] {
        ALU_ADD  = 4'd0,
        ALU_SUB  = 4'd1,
        ALU_SLL  = 4'd2,
        ALU_SLT  = 4'd3,
        ALU_SLTU = 4'd4,
        ALU_XOR  = 4'd5,
        ALU_SRL  = 4'd6,
        ALU_SRA  = 4'd7,
        ALU_OR   = 4'd8,
        ALU_AND  = 4'd9,
        ALU_COPY_B = 4'd10
    } alu_op_e;

endpackage

`default_nettype wire
