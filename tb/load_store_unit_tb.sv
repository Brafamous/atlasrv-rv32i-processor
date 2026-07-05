`timescale 1ns/1ps
`default_nettype none

import rv32i_pkg::*;

module load_store_unit_tb;

    logic [1:0]      addr_offset;
    load_type_e      load_type;
    logic [XLEN-1:0] dmem_rdata;
    logic [XLEN-1:0] load_data;

    store_type_e     store_type;
    logic [XLEN-1:0] store_data;
    logic [XLEN-1:0] store_wdata;
    logic [3:0]      store_be;

    load_store_unit dut (
        .addr_offset_i (addr_offset),
        .load_type_i   (load_type),
        .dmem_rdata_i  (dmem_rdata),
        .load_data_o   (load_data),
        .store_type_i  (store_type),
        .store_data_i  (store_data),
        .store_wdata_o (store_wdata),
        .store_be_o    (store_be)
    );

    task automatic check_load(
        input load_type_e      type_val,
        input logic [1:0]      offset_val,
        input logic [XLEN-1:0] rdata_val,
        input logic [XLEN-1:0] expected,
        input string           test_name
    );
        begin
            load_type   = type_val;
            addr_offset = offset_val;
            dmem_rdata  = rdata_val;
            #1;

            if (load_data !== expected) begin
                $display("FAIL LOAD: %s", test_name);
                $display("  load_data = 0x%08h expected 0x%08h", load_data, expected);
                $fatal;
            end else begin
                $display("PASS LOAD: %s", test_name);
            end
        end
    endtask

    task automatic check_store(
        input store_type_e     type_val,
        input logic [1:0]      offset_val,
        input logic [XLEN-1:0] data_val,
        input logic [XLEN-1:0] expected_wdata,
        input logic [3:0]      expected_be,
        input string           test_name
    );
        begin
            store_type  = type_val;
            addr_offset = offset_val;
            store_data  = data_val;
            #1;

            if ((store_wdata !== expected_wdata) || (store_be !== expected_be)) begin
                $display("FAIL STORE: %s", test_name);
                $display("  store_wdata = 0x%08h expected 0x%08h", store_wdata, expected_wdata);
                $display("  store_be    = 0b%04b expected 0b%04b", store_be, expected_be);
                $fatal;
            end else begin
                $display("PASS STORE: %s", test_name);
            end
        end
    endtask

    initial begin
        $display("Starting load/store unit directed tests...");

        // dmem_rdata bytes from low to high: 80, 7F, 34, 12
        check_load(LOAD_LB,  2'b00, 32'h1234_7F80, 32'hFFFF_FF80, "LB sign-extend byte 0 negative");
        check_load(LOAD_LB,  2'b01, 32'h1234_7F80, 32'h0000_007F, "LB sign-extend byte 1 positive");
        check_load(LOAD_LBU, 2'b00, 32'h1234_7F80, 32'h0000_0080, "LBU zero-extend byte 0");

        check_load(LOAD_LH,  2'b00, 32'h1234_8001, 32'hFFFF_8001, "LH sign-extend lower half negative");
        check_load(LOAD_LH,  2'b10, 32'h7FFF_8001, 32'h0000_7FFF, "LH sign-extend upper half positive");
        check_load(LOAD_LHU, 2'b00, 32'h1234_8001, 32'h0000_8001, "LHU zero-extend lower half");

        check_load(LOAD_LW,  2'b00, 32'hDEAD_BEEF, 32'hDEAD_BEEF, "LW full word");

        check_store(STORE_SB, 2'b00, 32'h0000_00AA, 32'h0000_00AA, 4'b0001, "SB byte lane 0");
        check_store(STORE_SB, 2'b01, 32'h0000_00AA, 32'h0000_AA00, 4'b0010, "SB byte lane 1");
        check_store(STORE_SB, 2'b10, 32'h0000_00AA, 32'h00AA_0000, 4'b0100, "SB byte lane 2");
        check_store(STORE_SB, 2'b11, 32'h0000_00AA, 32'hAA00_0000, 4'b1000, "SB byte lane 3");

        check_store(STORE_SH, 2'b00, 32'h0000_BEEF, 32'h0000_BEEF, 4'b0011, "SH lower half");
        check_store(STORE_SH, 2'b10, 32'h0000_BEEF, 32'hBEEF_0000, 4'b1100, "SH upper half");

        check_store(STORE_SW, 2'b00, 32'hCAFE_BABE, 32'hCAFE_BABE, 4'b1111, "SW full word");

        $display("All load/store unit tests passed.");
        $finish;
    end

endmodule

`default_nettype wire
