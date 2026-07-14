`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module wb_stage (
    input  logic [XLEN-1:0]  alu_result_i,
    input  logic [XLEN-1:0]  load_data_i,
    input  logic [XLEN-1:0]  pc_plus4_i,
    input  logic [4:0]       rd_addr_i,
    input  control_t         ctrl_i,

    output logic [4:0]       rd_addr_o,
    output logic [XLEN-1:0]  wdata_o,
    output logic             reg_write_o
);

    logic [XLEN-1:0] wb_data;

    always_comb begin
        unique case (ctrl_i.wb_sel)
            WB_ALU: wb_data = alu_result_i;
            WB_MEM: wb_data = load_data_i;
            WB_PC4: wb_data = pc_plus4_i;
            default: wb_data = alu_result_i;
        endcase
    end

    assign rd_addr_o   = rd_addr_i;
    assign wdata_o     = wb_data;
    assign reg_write_o = ctrl_i.reg_write;

endmodule

`default_nettype wire
