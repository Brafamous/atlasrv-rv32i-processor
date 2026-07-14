`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module forwarding_unit (
    input  logic [4:0] ex_rs1_addr_i,
    input  logic [4:0] ex_rs2_addr_i,

    input  logic [4:0] exmem_rd_addr_i,
    input  logic       exmem_reg_write_i,
    input  logic       exmem_is_load_i,

    input  logic [4:0] memwb_rd_addr_i,
    input  logic       memwb_reg_write_i,

    output logic [1:0] fwd_a_sel_o,
    output logic [1:0] fwd_b_sel_o
);

    localparam logic [1:0] FWD_NONE   = 2'b00;
    localparam logic [1:0] FWD_EX_MEM = 2'b01;
    localparam logic [1:0] FWD_MEM_WB = 2'b10;

    always_comb begin
        if (exmem_reg_write_i && !exmem_is_load_i &&
            (exmem_rd_addr_i != 5'd0) && (exmem_rd_addr_i == ex_rs1_addr_i)) begin
            fwd_a_sel_o = FWD_EX_MEM;
        end else if (memwb_reg_write_i &&
                     (memwb_rd_addr_i != 5'd0) && (memwb_rd_addr_i == ex_rs1_addr_i)) begin
            fwd_a_sel_o = FWD_MEM_WB;
        end else begin
            fwd_a_sel_o = FWD_NONE;
        end
    end

    always_comb begin
        if (exmem_reg_write_i && !exmem_is_load_i &&
            (exmem_rd_addr_i != 5'd0) && (exmem_rd_addr_i == ex_rs2_addr_i)) begin
            fwd_b_sel_o = FWD_EX_MEM;
        end else if (memwb_reg_write_i &&
                     (memwb_rd_addr_i != 5'd0) && (memwb_rd_addr_i == ex_rs2_addr_i)) begin
            fwd_b_sel_o = FWD_MEM_WB;
        end else begin
            fwd_b_sel_o = FWD_NONE;
        end
    end

    always_comb begin
        if (fwd_a_sel_o == FWD_EX_MEM) begin
            assert (exmem_reg_write_i && exmem_rd_addr_i != 5'd0)
                else $error("Illegal EX/MEM forward on rs1: reg_write=0 or rd=x0");
        end
        if (fwd_a_sel_o == FWD_MEM_WB) begin
            assert (memwb_reg_write_i && memwb_rd_addr_i != 5'd0)
                else $error("Illegal MEM/WB forward on rs1: reg_write=0 or rd=x0");
        end
        if (fwd_b_sel_o == FWD_EX_MEM) begin
            assert (exmem_reg_write_i && exmem_rd_addr_i != 5'd0)
                else $error("Illegal EX/MEM forward on rs2: reg_write=0 or rd=x0");
        end
        if (fwd_b_sel_o == FWD_MEM_WB) begin
            assert (memwb_reg_write_i && memwb_rd_addr_i != 5'd0)
                else $error("Illegal MEM/WB forward on rs2: reg_write=0 or rd=x0");
        end
        if (fwd_a_sel_o == FWD_MEM_WB && exmem_reg_write_i && !exmem_is_load_i &&
            exmem_rd_addr_i != 5'd0 && exmem_rd_addr_i == ex_rs1_addr_i) begin
            assert (1'b0)
                else $error("Priority violation: MEM/WB selected for rs1 while EX/MEM also matches");
        end
    end

endmodule

`default_nettype wire
