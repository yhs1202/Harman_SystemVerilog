`timescale 1ns / 1ps
`include "defines.sv"

module ControlUnit (
    input  logic [31:0] instrCode,
    output logic        regFileWe,
    output logic        aluSrcMuxSel,
    output logic [ 3:0] aluControl
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operator = {instrCode[30], instrCode[14:12]};
    logic [1:0] signals;

    assign {regFileWe, aluSrcMuxSel} = signals;

    always_comb begin
        signals = 2'b0;
        case (opcode)
               //{regFileWe, aluSrcMuxSel} 
            `OP_TYPE_R: signals = 2'b1_0;
            `OP_TYPE_I: signals = 2'b1_1;
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
        endcase
    end
endmodule
