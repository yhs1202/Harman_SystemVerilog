`timescale 1ns/1ps
module RV32I_core (
    input logic clk,
    input logic rst,
    input logic [31:0] instr_code,

    input logic [31:0] RAM_r_data,
    
    output logic [31:0] PC,
    output logic MemRead,
    output logic MemWrite,
    output logic [31:0] ALU_result,
    output logic [31:0] RAM_w_data,
    output logic [3:0] byte_enable // for future use
);

    // control signals
    logic ALUSrc_A;         // 0: rs1, 1: PC (for AUIPC)
    logic ALUSrc_B;         // 0: rs2
    logic [1:0] MemtoReg;   // 0: ALU result, 1: memory data, 2: PC+4 (for JAL), 3: imm (for LUI)
    logic RegWrite;
    logic Branch;
    logic [3:0] ALUControl; // see define.svh
    logic branch_taken;
    logic [1:0] PCSrc;

    control_unit U_CONTROL_UNIT (
        .instr_code(instr_code),
        .branch_taken(branch_taken),

        .ALUSrc_A(ALUSrc_A),
        .ALUSrc_B(ALUSrc_B),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .PCSrc(PCSrc),
        .ALUControl(ALUControl)
    );

    datapath U_DATAPATH (
        .clk(clk),
        .rst(rst),
        .instr_code(instr_code),
        .ALUSrc_A(ALUSrc_A),
        .ALUSrc_B(ALUSrc_B),
        .RegWrite(RegWrite),
        .RAM_r_data(RAM_r_data),
        .Branch(Branch),
        .PCSrc(PCSrc),
        .ALUControl(ALUControl),
        .MemtoReg(MemtoReg),

        .ALU_result(ALU_result),
        .RAM_w_data(RAM_w_data),
        .byte_enable(byte_enable),
        .branch_taken(branch_taken),
        .PC(PC)
    );

    // RAM U_RAM (
    //     .clk(clk),
    //     .MemRead(MemRead),
    //     .MemWrite(MemWrite),
    //     .func3(instr_code[14:12]),  // 0-> b, 1-> h, 2-> w, 4-> ub, 5-> uh
    //     .addr(ALU_result),
    //     .w_data(RAM_w_data),

    //     .r_data(RAM_r_data)
    // );

endmodule