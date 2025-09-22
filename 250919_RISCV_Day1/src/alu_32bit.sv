`timescale 1ns/1ps
module alu_32bit (
    input logic [2:0] ALUOp,
    input logic [3:0] ALUControl,
    input logic [31:0] a,
    input logic [31:0] b,

    output logic N, Z, C, V,
    output logic [31:0] result
);

    enum logic [3:0] {
        ADD = 4'b0000, 
        SUB = 4'b0001, 
        XOR = 4'b0010, 
        OR  = 4'b0011, 
        AND = 4'b0100, 
        SLL = 4'b0101, 
        SRL = 4'b0110, 
        SRA = 4'b0111, 
        SLT = 4'b1000, 
        SLTU = 4'b1001
    } operation;

    assign N = result[31];
    assign Z = (result == 32'b0);
    assign V = (a[31] == b[31]) && (result[31] != a[31]);  // Carry in != Carry out for MSB

    always_comb begin : ALU_operations
        // Determine operation based on ALUOp and ALUControl
        case (ALUOp)
            3'b000: begin   // Load/Store
            end
            3'b001: begin   // Branch
            end
            3'b010: begin   // R-type
                case (ALUControl)
                    ADD: {C, result} = a + b;
                    SUB: {C, result} = a - b;
                    XOR: result = a ^ b;
                    OR: result = a | b;
                    AND: result = a & b;
                    SLL: result = a << b[4:0];
                    SRL: result = a >> b[4:0];
                    SRA: result = a >>> b[4:0];
                    SLT: result = {31'b0, a < b};
                    SLTU: result = {31'b0, $unsigned(a) < $unsigned(b)};
                    default: result = 32'bx;    // NO OPERATION
                endcase
            end
            /*
            3'b011: begin   // I-type
            end
            3'b100: begin   // JAL
            end
            */
            default: result = 32'bx; // NO OPERATION
        endcase
        
    end

endmodule