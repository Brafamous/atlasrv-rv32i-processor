`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module data_memory_model #(
    parameter int MEM_DEPTH_BYTES = 4096
) (
    input  logic                clk_i,

    input  logic [XLEN-1:0]     addr_i,
    input  logic [XLEN-1:0]     wdata_i,
    input  logic [3:0]          be_i,
    input  logic                we_i,
    input  logic                re_i,

    output logic [XLEN-1:0]     rdata_o
);

    logic [7:0] mem [0:MEM_DEPTH_BYTES-1];

    integer i;

    initial begin
        for (i = 0; i < MEM_DEPTH_BYTES; i = i + 1) begin
            mem[i] = 8'h00;
        end
    end

    logic [XLEN-1:0] word_base;
    assign word_base = {addr_i[XLEN-1:2], 2'b00};

    // ------------------------------------------------------------
    // Combinational read, gated by re_i.
    //
    // re_i = 1 and address in range -> rdata_o is architecturally
    //         valid and reflects stored bytes.
    // re_i = 0, or address out of range -> rdata_o is defined as
    //         zero and must be ignored by anything downstream.
    // ------------------------------------------------------------
    always_comb begin
        if (re_i && ((word_base + 32'd3) < MEM_DEPTH_BYTES)) begin
            rdata_o = { mem[word_base + 32'd3], mem[word_base + 32'd2],
                        mem[word_base + 32'd1], mem[word_base + 32'd0] };
        end else begin
            rdata_o = '0;
        end
    end

    // ------------------------------------------------------------
    // Synchronous, byte-enabled write. Out-of-range write fails
    // loud via $fatal, same discipline as instruction_memory_model.
    // re_i and we_i may be asserted together: this is read-old-data
    // behavior -- rdata_o reflects the pre-edge contents, the write
    // commits at the edge, and a subsequent read sees the new value.
    // ------------------------------------------------------------
    always_ff @(posedge clk_i) begin
        if (we_i) begin
            if ((word_base + 32'd3) >= MEM_DEPTH_BYTES) begin
                $fatal(1, "Data memory write address 0x%08h is out of range", addr_i);
            end
            if (be_i[0]) mem[word_base + 32'd0] <= wdata_i[7:0];
            if (be_i[1]) mem[word_base + 32'd1] <= wdata_i[15:8];
            if (be_i[2]) mem[word_base + 32'd2] <= wdata_i[23:16];
            if (be_i[3]) mem[word_base + 32'd3] <= wdata_i[31:24];
        end
    end

endmodule

`default_nettype wire
