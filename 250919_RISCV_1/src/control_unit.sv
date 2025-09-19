`timescale 1ns/1ps

module control_unit (
    input logic clk,
    input logic rst,
    input logic [31:0] instruction_code,

    output logic Reg_write,
    output logic [2:0] ALUOp,
    output logic [3:0] ALUControl
);

    logic [6:0] func7;
    logic [2:0] func3;
    logic [6:0] opcode;
    assign func7 = instruction_code[31:25];
    assign func3 = instruction_code[14:12];
    assign opcode = instruction_code[6:0];

    // Decode instruction
    always_comb begin : opcode_decoder
        case (opcode)
            7'b000_0011: ALUOp = 3'b000; // Load
            7'b010_0011: ALUOp = 3'b000; // Store
            7'b110_0011: ALUOp = 3'b001; // Branch
            7'b011_0011: ALUOp = 3'b010; // R-type
            7'b001_0011: ALUOp = 3'b011; // I-type
            7'b110_1111: ALUOp = 3'b100; // JAL
            default:    ALUOp = 3'b111; // NOP/illegal
    endcase
    end

    always_comb begin : ALU_decoder
        unique case (ALUOp)
            3'b000: begin // Load/Store
            end
            3'b001: begin // Branch
            end
            3'b010: begin // R-type
                unique case ({func7, func3})
                    10'b0000000_000: ALUControl = 4'b0000; // ADD
                    10'b0100000_000: ALUControl = 4'b0001; // SUB
                    10'b0000000_100: ALUControl = 4'b0010; // XOR
                    10'b0000000_110: ALUControl = 4'b0011; // OR
                    10'b0000000_111: ALUControl = 4'b0100; // AND
                    10'b0000000_001: ALUControl = 4'b0101; // SLL
                    10'b0000000_101: ALUControl = 4'b0110; // SRL
                    10'b0100000_101: ALUControl = 4'b0111; // SRA
                    10'b0000000_010: ALUControl = 4'b1000; // SLT
                    10'b0000000_011: ALUControl = 4'b1001; // SLTU
                    default: ALUControl = 4'bxxxx; // Default to ADD
                endcase
                Reg_write = 1'b1;
            end
            /*
            3'b011: begin // I-type
                unique case (func3)
                    3'b000: ALUControl = 4'b0000; // ADDI
                    3'b010: ALUControl = 4'b1000; // SLTI
                    3'b110: ALUControl = 4'b0110; // ORI
                    default: ALUControl = 4'bxxxx; // Default to ADDI
                endcase
                Reg_write = 1'b1;
            end
            3'b100: begin // JAL
                ALUControl = 4'bxxxx; // No ALU operation needed
                Reg_write = 1'b1; // Write return address to rd
            end
            */
            default: begin // NOP/illegal
                ALUControl = 4'bxxxx;
                Reg_write = 1'b0;
            end
        endcase
    end
endmodule