`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic        aluSrcMuxSel,
    output logic [ 3:0] aluControl,
    output logic [ 2:0] strb,
    output logic        busWe,
    output logic [ 2:0] RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal,
    output logic        jalr
);
    wire  [6:0] opcode = instrCode[6:0];
    wire  [3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [8:0] signals;

    assign {regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal, jalr} = signals;
    assign strb = instrCode[14:12];

    always_comb begin
        signals = 9'b0;
        case (opcode)
            //{regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel(3), branch, jal, jalr} 
            `OP_TYPE_R:      signals = 9'b1_0_0_000_0_0_0;
            `OP_TYPE_I:      signals = 9'b1_1_0_000_0_0_0;
            `OP_TYPE_S:      signals = 9'b0_1_1_000_0_0_0;
            `OP_TYPE_L:      signals = 9'b1_1_0_001_0_0_0;
            `OP_TYPE_B:      signals = 9'b0_0_0_000_1_0_0;
            `OP_TYPE_LU:     signals = 9'b1_0_0_010_0_0_0;
            `OP_TYPE_AU:     signals = 9'b1_0_0_011_0_0_0;
            `OP_TYPE_J:      signals = 9'b1_0_0_100_0_1_0;
            `OP_TYPE_JL:     signals = 9'b1_0_0_100_0_1_1;
        endcase
    end

    always_comb begin
        aluControl = `ADD;
        case (opcode)
            `OP_TYPE_R: aluControl = operator;
            `OP_TYPE_B: aluControl = operator;
            `OP_TYPE_I: begin
                if (operator == 4'b1101) aluControl = operator;
                else aluControl = {1'b0, operator[2:0]};
            end
        endcase
    end
endmodule
