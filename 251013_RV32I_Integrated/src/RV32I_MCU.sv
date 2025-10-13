`timescale 1ns/1ps

module RV32I_MCU (
    input logic clk,
    input logic rst
);
    logic [31:0] PC;
    logic [31:0] instr_code;

    ROM U_ROM (
        .addr (PC),
        .instr_code (instr_code)
    );

    RV32I_core U_RV32I_CORE (
        .clk (clk),
        .rst (rst),
        .instr_code (instr_code),

        .PC (PC)
    );  
endmodule