`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic        aluSrcMuxSel,
    output logic [ 3:0] aluControl,
    output logic [2:0] strb,
    output logic busWe,
    output logic [1:0] MemtoReg_Sel // for lui to initialize with immediate value
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [2:0] signals;

    assign {regFileWe, aluSrcMuxSel, busWe} = signals;
    assign strb = instrCode[14:12];

    always_comb begin
        signals = 3'b0;
        case (opcode)
               //{regFileWe, aluSrcMuxSel, busWe} 
            `OP_TYPE_R: signals = 3'b1_0_0;
            `OP_TYPE_I: signals = 3'b1_1_0;
            `OP_TYPE_S: signals = 3'b0_1_1;
            `OP_TYPE_I_LOAD: signals = 3'b1_1_0;
            `OP_TYPE_U_LUI: signals = 3'b1_1_0; // for lui to initialize with immediate value
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
            `OP_TYPE_S: aluControl = `ADD;
        endcase
    end

    always_comb begin : MemtoReg_decoder
        case (opcode)
        `OP_TYPE_I_LOAD:
            MemtoReg_Sel = 2'b01; // Load from memory
        `OP_TYPE_J_JAL, `OP_TYPE_I_JALR:
            MemtoReg_Sel = 2'b10; // PC + 4 for JAL and JALR
        `OP_TYPE_U_LUI:
            MemtoReg_Sel = 2'b11; // immediate for LUI
        default: 
            MemtoReg_Sel = 2'b00; // Default to ALU result
        endcase
    end
endmodule
