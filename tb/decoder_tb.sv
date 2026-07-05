`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module decoder_tb;

    logic [INSTR_W-1:0] instr;
    control_t           ctrl;

    decoder dut (
        .instr_i (instr),
        .ctrl_o  (ctrl)
    );

    task automatic check(
        input logic [INSTR_W-1:0] instr_val,
        input alu_op_e            exp_alu_op,
        input imm_type_e          exp_imm_type,
        input branch_type_e       exp_branch_type,
        input wb_sel_e            exp_wb_sel,
        input logic               exp_reg_write,
        input logic               exp_mem_read,
        input logic               exp_mem_write,
        input logic               exp_jump,
        input string              test_name
    );
        begin
            instr = instr_val;
            #1;

            if ((ctrl.alu_op      !== exp_alu_op)      ||
                (ctrl.imm_type    !== exp_imm_type)    ||
                (ctrl.branch_type !== exp_branch_type) ||
                (ctrl.wb_sel      !== exp_wb_sel)      ||
                (ctrl.reg_write   !== exp_reg_write)   ||
                (ctrl.mem_read    !== exp_mem_read)    ||
                (ctrl.mem_write   !== exp_mem_write)   ||
                (ctrl.jump        !== exp_jump)) begin

                $display("FAIL: %s", test_name);
                $display("  alu_op      = %0d expected %0d", ctrl.alu_op, exp_alu_op);
                $display("  imm_type    = %0d expected %0d", ctrl.imm_type, exp_imm_type);
                $display("  branch_type = %0d expected %0d", ctrl.branch_type, exp_branch_type);
                $display("  wb_sel      = %0d expected %0d", ctrl.wb_sel, exp_wb_sel);
                $display("  reg_write   = %0b expected %0b", ctrl.reg_write, exp_reg_write);
                $display("  mem_read    = %0b expected %0b", ctrl.mem_read, exp_mem_read);
                $display("  mem_write   = %0b expected %0b", ctrl.mem_write, exp_mem_write);
                $display("  jump        = %0b expected %0b", ctrl.jump, exp_jump);
                $fatal;
            end else begin
                $display("PASS: %s", test_name);
            end
        end
    endtask

    initial begin
        $display("Starting decoder directed tests...");

        // R-Type
        check(32'h0020_82B3, ALU_ADD,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type ADD");
        check(32'h4020_82B3, ALU_SUB,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type SUB");
        check(32'h0020_91B3, ALU_SLL,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type SLL");
        check(32'h0020_A1B3, ALU_SLT,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type SLT");
        check(32'h0020_B1B3, ALU_SLTU, IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type SLTU");
        check(32'h0020_C1B3, ALU_XOR,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type XOR");
        check(32'h0020_D1B3, ALU_SRL,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type SRL");
        check(32'h4020_D1B3, ALU_SRA,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type SRA");
        check(32'h0020_E1B3, ALU_OR,   IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type OR");
        check(32'h0020_F1B3, ALU_AND,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "R-Type AND");

        // I-Type ALU
        check(32'h00A0_8293, ALU_ADD,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type ADDI");
        check(32'h00A0_A293, ALU_SLT,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type SLTI");
        check(32'h00A0_B293, ALU_SLTU, IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type SLTIU");
        check(32'h00A0_C293, ALU_XOR,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type XORI");
        check(32'h00A0_E293, ALU_OR,   IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type ORI");
        check(32'h00A0_F293, ALU_AND,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type ANDI");
        check(32'h0010_9293, ALU_SLL,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type SLLI");
        check(32'h0010_D293, ALU_SRL,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type SRLI");
        check(32'h4010_D293, ALU_SRA,  IMM_I, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "I-Type SRAI");

        // Loads and stores
        check(32'h0001_2283, ALU_ADD, IMM_I, BR_NONE, WB_MEM, 1'b1, 1'b1, 1'b0, 1'b0, "LOAD");
        check(32'h0051_2023, ALU_ADD, IMM_S, BR_NONE, WB_ALU, 1'b0, 1'b0, 1'b1, 1'b0, "STORE");

        // Branches
        check(32'h0020_8063, ALU_SUB, IMM_B, BR_BEQ,  WB_ALU, 1'b0, 1'b0, 1'b0, 1'b0, "BEQ");
        check(32'h0020_9063, ALU_SUB, IMM_B, BR_BNE,  WB_ALU, 1'b0, 1'b0, 1'b0, 1'b0, "BNE");
        check(32'h0020_C063, ALU_SUB, IMM_B, BR_BLT,  WB_ALU, 1'b0, 1'b0, 1'b0, 1'b0, "BLT");
        check(32'h0020_D063, ALU_SUB, IMM_B, BR_BGE,  WB_ALU, 1'b0, 1'b0, 1'b0, 1'b0, "BGE");
        check(32'h0020_E063, ALU_SUB, IMM_B, BR_BLTU, WB_ALU, 1'b0, 1'b0, 1'b0, 1'b0, "BLTU");
        check(32'h0020_F063, ALU_SUB, IMM_B, BR_BGEU, WB_ALU, 1'b0, 1'b0, 1'b0, 1'b0, "BGEU");

        // Jumps and upper immediate
        check(32'h0000_00EF, ALU_ADD,    IMM_J, BR_NONE, WB_PC4, 1'b1, 1'b0, 1'b0, 1'b1, "JAL");
        check(32'h0001_00E7, ALU_ADD,    IMM_I, BR_NONE, WB_PC4, 1'b1, 1'b0, 1'b0, 1'b1, "JALR");
        check(32'h1234_52B7, ALU_COPY_B, IMM_U, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "LUI");
        check(32'h1234_5297, ALU_ADD,    IMM_U, BR_NONE, WB_ALU, 1'b1, 1'b0, 1'b0, 1'b0, "AUIPC");

        $display("All decoder tests passed.");
        $finish;
    end

endmodule

`default_nettype wire

