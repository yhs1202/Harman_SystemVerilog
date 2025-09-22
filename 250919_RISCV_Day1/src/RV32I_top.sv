`timescale 1ns/1ps
module RV32I_top (
    input logic clk,
    input logic rst

);
    logic [31:0] PC;
    logic [31:0] instruction_code;

    logic Reg_write;

    logic [2:0] ALUOp;
    logic [31:0] ALU_result;


    instruction_mem U_INSTRUCTION_MEM (
        .addr(PC),
        .instruction_code(instruction_code)
    );

    control_unit U_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .instruction_code(instruction_code),
        .Reg_write(Reg_write),
        .ALUOp(ALUOp)
    );

    datapath U_DATAPATH (
        .clk(clk),
        .rst(rst),
        .instruction_code(instruction_code),
        .ALUOp(ALUOp),
        .Reg_write(Reg_write),
        .PC(PC),
        .ALU_result(ALU_result)
    );

endmodule