`timescale 1ns/1ps
module APB_Interface_top (
    input logic PCLK,
    input logic PRESET
);

    logic [31:0] PADDR;
    logic PWRITE;
    logic PENABLE;
    logic [31:0] PWDATA;
    logic PSEL0;
    logic PSEL1;
    logic PSEL2;
    logic PSEL3;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic PREADY0;
    logic PREADY1;
    logic PREADY2;
    logic PREADY3;

    logic transfer;
    logic write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic ready;

    APB_Manager U_APB_MANAGER (.*);
    APB_test_master U_APB_TEST_MASTER (.*);
    APB_test_slave U_APB_TEST_slave_0 (
        .*,
        .PSEL(PSEL0),
        .PRDATA(PRDATA0),
        .PREADY(PREADY0)
    );
    APB_test_slave U_APB_TEST_slave_1 (
        .*,
        .PSEL(PSEL1),
        .PRDATA(PRDATA1),
        .PREADY(PREADY1)
    );
    APB_test_slave U_APB_TEST_slave_2 (
        .*,
        .PSEL(PSEL2),
        .PRDATA(PRDATA2),
        .PREADY(PREADY2)
    );
    APB_test_slave U_APB_TEST_slave_3 (
        .*,
        .PSEL(PSEL3),
        .PRDATA(PRDATA3),
        .PREADY(PREADY3)
    );
    
endmodule