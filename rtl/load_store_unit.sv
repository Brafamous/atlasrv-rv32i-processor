`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module load_store_unit (
    input  logic [1:0]        addr_offset_i,

    input  load_type_e        load_type_i,
    input  logic [XLEN-1:0]   dmem_rdata_i,
    output logic [XLEN-1:0]   load_data_o,

    input  store_type_e       store_type_i,
    input  logic [XLEN-1:0]   store_data_i,
    output logic [XLEN-1:0]   store_wdata_o,
    output logic [3:0]        store_be_o
);

    logic [7:0]  selected_byte;
    logic [15:0] selected_halfword;

    always_comb begin
        unique case (addr_offset_i)
            2'b00: selected_byte = dmem_rdata_i[7:0];
            2'b01: selected_byte = dmem_rdata_i[15:8];
            2'b10: selected_byte = dmem_rdata_i[23:16];
            2'b11: selected_byte = dmem_rdata_i[31:24];
            default: selected_byte = 8'h00;
        endcase

        unique case (addr_offset_i[1])
            1'b0: selected_halfword = dmem_rdata_i[15:0];
            1'b1: selected_halfword = dmem_rdata_i[31:16];
            default: selected_halfword = 16'h0000;
        endcase
    end

    always_comb begin
        unique case (load_type_i)
            LOAD_LB:  load_data_o = {{24{selected_byte[7]}}, selected_byte};
            LOAD_LH:  load_data_o = {{16{selected_halfword[15]}}, selected_halfword};
            LOAD_LW:  load_data_o = dmem_rdata_i;
            LOAD_LBU: load_data_o = {24'h000000, selected_byte};
            LOAD_LHU: load_data_o = {16'h0000, selected_halfword};
            default:  load_data_o = '0;
        endcase
    end

    always_comb begin
        store_wdata_o = '0;
        store_be_o    = 4'b0000;

        unique case (store_type_i)
            STORE_SB: begin
                store_wdata_o = {{24{1'b0}}, store_data_i[7:0]} << (addr_offset_i * 8);
                store_be_o    = 4'b0001 << addr_offset_i;
            end

            STORE_SH: begin
                store_wdata_o = {{16{1'b0}}, store_data_i[15:0]} << (addr_offset_i[1] * 16);
                store_be_o    = 4'b0011 << (addr_offset_i[1] * 2);
            end

            STORE_SW: begin
                store_wdata_o = store_data_i;
                store_be_o    = 4'b1111;
            end

            default: begin
                store_wdata_o = '0;
                store_be_o    = 4'b0000;
            end
        endcase
    end

endmodule

`default_nettype wire
