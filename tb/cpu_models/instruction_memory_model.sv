`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module instruction_memory_model #(
    parameter int MEM_DEPTH_WORDS = 256
) (
    input  logic [XLEN-1:0]    addr_i,
    output logic [INSTR_W-1:0] instr_o
);

    localparam logic [INSTR_W-1:0] NOP = 32'h0000_0013; // addi x0, x0, 0

    localparam int IDX_W =
        (MEM_DEPTH_WORDS <= 1) ? 1 : $clog2(MEM_DEPTH_WORDS);

    logic [INSTR_W-1:0] mem [0:MEM_DEPTH_WORDS-1];
    logic [XLEN-1:0]    word_addr;

    integer i;

    assign word_addr = addr_i >> 2;

    initial begin
        for (i = 0; i < MEM_DEPTH_WORDS; i = i + 1) begin
            mem[i] = NOP;
        end
    end

    always_comb begin
        if (word_addr < MEM_DEPTH_WORDS) begin
            instr_o = mem[word_addr[IDX_W-1:0]];
        end else begin
            instr_o = NOP;
        end
    end

    task automatic write_word(
        input int unsigned        index,
        input logic [INSTR_W-1:0] word
    );
        if (index >= MEM_DEPTH_WORDS) begin
            $fatal(1, "Instruction memory write index %0d is out of range", index);
        end
        mem[index] = word;
    endtask

endmodule

`default_nettype wire
