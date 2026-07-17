`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module hazard_detection_unit (
    input  logic [4:0] id_rs1_addr_i,
    input  logic [4:0] id_rs2_addr_i,

    input  logic [4:0] idex_rd_addr_i,
    input  logic       idex_mem_read_i,

    output logic       stall_o
);

    always_comb begin
        if (idex_mem_read_i && (idex_rd_addr_i != 5'd0) &&
            ((idex_rd_addr_i == id_rs1_addr_i) || (idex_rd_addr_i == id_rs2_addr_i))) begin
            stall_o = 1'b1;
        end else begin
            stall_o = 1'b0;
        end

        if (stall_o) begin
            assert (idex_mem_read_i)
                else $error("Stall asserted for a non-load producer -- unnecessary stall");
        end
    end

endmodule

`default_nettype wire
