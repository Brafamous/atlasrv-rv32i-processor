`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module rv32i_single_cycle_core (

    input  logic clk,
    input  logic rst_n,

    //============================================================
    // Instruction Memory Interface
    //============================================================

    output logic [XLEN-1:0] imem_addr_o,
    input  logic [INSTR_W-1:0] imem_rdata_i,

    //============================================================
    // Data Memory Interface
    //============================================================

    output logic [XLEN-1:0] dmem_addr_o,
    output logic [XLEN-1:0] dmem_wdata_o,
    output logic [3:0]      dmem_be_o,
    output logic            dmem_we_o,
    output logic            dmem_re_o,

    input  logic [XLEN-1:0] dmem_rdata_i

);

    //============================================================
    // FETCH STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] pc_q;
    logic [XLEN-1:0] pc_next;
    logic [XLEN-1:0] pc_plus4;

    logic [INSTR_W-1:0] instruction;

    //============================================================
    // DECODE STAGE SIGNALS
    //============================================================

    control_t ctrl;

    logic [REG_ADDR_W-1:0] rs1_addr;
    logic [REG_ADDR_W-1:0] rs2_addr;
    logic [REG_ADDR_W-1:0] rd_addr;

    logic [XLEN-1:0] rs1_data;
    logic [XLEN-1:0] rs2_data;

    logic [XLEN-1:0] immediate;

    //============================================================
    // EXECUTE STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] alu_operand_a;
    logic [XLEN-1:0] alu_operand_b;

    logic [XLEN-1:0] alu_result;

    logic branch_taken;

    //============================================================
    // MEMORY STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] load_data;

    //============================================================
    // WRITEBACK STAGE SIGNALS
    //============================================================

    logic [XLEN-1:0] writeback_data;

    //============================================================
    // FETCH: Program Counter and Instruction Interface
    //============================================================

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pc_q <= RESET_VECTOR;
        end else begin
            pc_q <= pc_next;
        end
    end

    assign pc_plus4   = pc_q + 32'd4;
    logic [XLEN-1:0] branch_target;
    logic [XLEN-1:0] jalr_target;

    assign branch_target = pc_q + immediate;
    assign jalr_target   = (rs1_data + immediate) & ~32'h0000_0001;

    always_comb begin
        pc_next = pc_plus4;

        if (ctrl.jump) begin
            if (instruction[6:0] == OPCODE_JALR) begin
                pc_next = jalr_target;
            end else begin
                pc_next = branch_target;
            end
        end else if (branch_taken) begin
            pc_next = branch_target;
        end
    end

    assign imem_addr_o = pc_q;
    assign instruction = imem_rdata_i;

    //============================================================
    // DECODE: Instruction Field Extraction
    //============================================================

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];

    //============================================================
    // DECODE: Control and Immediate Generation
    //============================================================

    decoder u_decoder (
        .instr_i (instruction),
        .ctrl_o  (ctrl)
    );

    imm_gen u_imm_gen (
        .instr_i    (instruction),
        .imm_type_i (ctrl.imm_type),
        .imm_o      (immediate)
    );

    //============================================================
    // MEMORY: Data Memory Interface and Load/Store Formatting
    //============================================================

    load_store_unit u_load_store_unit (
        .addr_offset_i (alu_result[1:0]),

        .load_type_i   (ctrl.load_type),
        .dmem_rdata_i  (dmem_rdata_i),
        .load_data_o   (load_data),

        .store_type_i  (ctrl.store_type),
        .store_data_i  (rs2_data),
        .store_wdata_o (dmem_wdata_o),
        .store_be_o    (dmem_be_o)
    );

    assign dmem_addr_o = alu_result;
    assign dmem_we_o   = ctrl.mem_write;
    assign dmem_re_o   = ctrl.mem_read;
    

    //============================================================
    // DECODE/WRITEBACK: Register File
    //============================================================

    regfile u_regfile (
        .clk        (clk),
        .rst_n      (rst_n),
        .rs1_addr_i (rs1_addr),
        .rs2_addr_i (rs2_addr),
        .rs1_data_o (rs1_data),
        .rs2_data_o (rs2_data),
        .rd_we_i    (ctrl.reg_write),
        .rd_addr_i  (rd_addr),
        .rd_data_i  (writeback_data)
    );

    //============================================================
    // EXECUTE: ALU Operand Selection
    //============================================================

    always_comb begin
        unique case (ctrl.alu_src_a)
            ALU_SRC_A_RS1:  alu_operand_a = rs1_data;
            ALU_SRC_A_PC:   alu_operand_a = pc_q;
            ALU_SRC_A_ZERO: alu_operand_a = '0;
            default:        alu_operand_a = rs1_data;
        endcase
    end

    always_comb begin
        unique case (ctrl.alu_src_b)
            ALU_SRC_B_RS2:  alu_operand_b = rs2_data;
            ALU_SRC_B_IMM:  alu_operand_b = immediate;
            ALU_SRC_B_FOUR: alu_operand_b = 32'd4;
            default:        alu_operand_b = rs2_data;
        endcase
    end

    //============================================================
    // EXECUTE: ALU
    //============================================================

    alu u_alu (
        .a_i       (alu_operand_a),
        .b_i       (alu_operand_b),
        .alu_op_i  (ctrl.alu_op),
        .result_o  (alu_result)
    );

    //============================================================
    // EXECUTE: Branch Unit
    //============================================================

    branch_unit u_branch_unit (
        .a_i            (rs1_data),
        .b_i            (rs2_data),
        .branch_type_i  (ctrl.branch_type),
        .branch_taken_o (branch_taken)
    );


    //============================================================
    // WRITEBACK: Writeback MUX
    //============================================================

    always_comb begin
        unique case (ctrl.wb_sel)
            WB_ALU:  writeback_data = alu_result;
            WB_MEM:  writeback_data = load_data;
            WB_PC4:  writeback_data = pc_plus4;
            default: writeback_data = '0;
        endcase
    end


endmodule

`default_nettype wire
