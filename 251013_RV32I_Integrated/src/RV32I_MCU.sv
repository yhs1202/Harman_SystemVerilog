`timescale 1ns/1ps

module RV32I_MCU (
    input logic clk,
    input logic rst
);
    logic [31:0] PC;
    logic [31:0] instr_code;

    logic MemRead;
    logic MemWrite;
    logic [31:0] ALU_result;
    logic [31:0] MEM_r_data;
    logic [31:0] MEM_w_data;
    logic [3:0] byte_enable;
    

    ROM U_ROM (
        .addr (PC),
        .instr_code (instr_code)
    );

    RV32I_core U_RV32I_CORE (
        .clk (clk),
        .rst (rst),
        .instr_code (instr_code),
        .MEM_r_data (MEM_r_data),

        .PC (PC),
        .MemRead (MemRead),
        .MemWrite (MemWrite),
        .ALU_result (ALU_result),
        .MEM_w_data (MEM_w_data),
        .byte_enable (byte_enable)
    );

    RAM_with_BE U_RAM (
        .clk(clk),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .byte_enable(byte_enable),
        .addr(ALU_result),
        .w_data(MEM_w_data),

        .r_data(MEM_r_data)
    );
    // for measureing LUT
    (* keep = "true" *) logic [7:0] debug_led;
    assign debug_led = U_RV32I_CORE.PC[9:2];
endmodule