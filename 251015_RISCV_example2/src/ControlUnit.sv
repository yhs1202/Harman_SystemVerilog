`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic        aluSrcMuxSel,
    output logic [ 3:0] aluControl,
    output logic [ 2:0] strb,
    output logic        busWe,
    output logic  [2:0]      RFWDSrcMuxSel,
    output logic        branch,
    output logic        jal
);
    wire  [6:0] opcode = instrCode[6:0];
    wire  [3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [7:0] signals;

    assign {regFileWe, aluSrcMuxSel, busWe, RFWDSrcMuxSel, branch, jal} = signals;
    assign strb = instrCode[14:12];

    always_comb begin
        signals = 8'b0;
        case (opcode)
            //{regFileWe, aluSrcMuxSel, dataWe, RFWDSrcMuxSel, branch, jal} 
            `OP_TYPE_R:       signals = 8'b1_0_0_000_0_0;
            `OP_TYPE_I:       signals = 8'b1_1_0_000_0_0;
            `OP_TYPE_S:       signals = 8'b0_1_1_000_0_0;
            `OP_TYPE_L:       signals = 8'b1_1_0_001_0_0;
            `OP_TYPE_B:       signals = 8'b0_0_0_000_1_0;
            `OP_TYPE_U_LUI:   signals = 8'b1_0_0_010_0_0;
            `OP_TYPE_U_AUIPC: signals = 8'b1_1_0_011_0_0;
            `OP_TYPE_J_JAL:   signals = 8'b1_0_0_100_0_1;
            `OP_TYPE_I_JALR:  signals = 8'b1_1_0_100_0_1;

        endcase
    end

    always_comb begin
        aluControl = `ADD;
        case (opcode)
            `OP_TYPE_R: aluControl = operator;
            `OP_TYPE_I: begin
                if (operator == 4'b1101) aluControl = operator;
                else aluControl = {1'b0, operator[2:0]};
            end
            `OP_TYPE_S, `OP_TYPE_L, `OP_TYPE_I_JALR: aluControl = `ADD;
            `OP_TYPE_B: aluControl = operator;
        endcase
    end
endmodule
