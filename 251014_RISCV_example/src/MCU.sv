`timescale 1ns / 1ps

module MCU (
    input logic clk,
    input logic reset
);

    logic [31:0] instrCode, instrMemAddr;

    ROM U_ROM (
        .addr(instrMemAddr),
        .data(instrCode)
    );

    CPU_RV32I U_RV32I (
        .clk(clk),
        .reset(reset),
        .instrCode(instrCode),
        .instrMemAddr(instrMemAddr)
    );
endmodule
