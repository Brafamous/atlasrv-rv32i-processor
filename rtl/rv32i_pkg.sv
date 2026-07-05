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
    // RV32I Opcodes
    // ------------------------------------------------------------

    parameter logic [6:0] OPCODE_R_TYPE = 7'b0110011;
    parameter logic [6:0] OPCODE_I_TYPE = 7'b0010011;

    parameter logic [6:0] OPCODE_LOAD   = 7'b0000011;
    parameter logic [6:0] OPCODE_STORE  = 7'b0100011;

    parameter logic [6:0] OPCODE_BRANCH = 7'b1100011;

    parameter logic [6:0] OPCODE_JAL    = 7'b1101111;
    parameter logic [6:0] OPCODE_JALR   = 7'b1100111;

    parameter logic [6:0] OPCODE_LUI    = 7'b0110111;
    parameter logic [6:0] OPCODE_AUIPC  = 7'b0010111;

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
// ------------------------------------------------------------
// Immediate format selection
// ------------------------------------------------------------

typedef enum logic [2:0] {
    IMM_I,
    IMM_S,
    IMM_B,
    IMM_U,
    IMM_J
} imm_type_e;

    // ------------------------------------------------------------
    // Branch operation selection
    // ------------------------------------------------------------

    typedef enum logic [2:0] {
        BR_NONE,
        BR_BEQ,
        BR_BNE,
        BR_BLT,
        BR_BGE,
        BR_BLTU,
        BR_BGEU
    } branch_type_e;

    // ------------------------------------------------------------
    // Register write-back source
    // ------------------------------------------------------------

    typedef enum logic [1:0] {
        WB_ALU,
        WB_MEM,
        WB_PC4
    } wb_sel_e;

    // ------------------------------------------------------------
    // Decoder control bundle
    // ------------------------------------------------------------

    typedef struct packed {

        alu_op_e      alu_op;

        imm_type_e    imm_type;

        branch_type_e branch_type;

        wb_sel_e      wb_sel;

        logic reg_write;

        logic mem_read;

        logic mem_write;

        logic jump;

    } control_t;


        // ------------------------------------------------------------
    // Load operation selection
    // ------------------------------------------------------------

    typedef enum logic [2:0] {
        LOAD_LB,
        LOAD_LH,
        LOAD_LW,
        LOAD_LBU,
        LOAD_LHU
    } load_type_e;

    // ------------------------------------------------------------
    // Store operation selection
    // ------------------------------------------------------------

    typedef enum logic [1:0] {
        STORE_SB,
        STORE_SH,
        STORE_SW
    } store_type_e;

endpackage

`default_nettype wire
