`timescale 1ns/1ps
module pc_logic (
    input logic clk,
    input logic rst,
    input logic [31:0] pc_branch_offset,
    input logic [31:0] ALU_result,
    input logic [1:0] PCSel,    // 00: PC+4, 01: branch, 10: jump, 11: jalr
    
    output logic [31:0] PC_Plus4,
    output logic [31:0] PC_next
);

    logic [31:0] PC_reg;

    assign PC_Plus4 = PC_next + 32'd4;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            PC_next <= 32'b0;
        end else begin
            PC_next <= PC_reg;
        end
    end

    always_comb begin
        case (PCSel)
            // PC + 4
            2'b00: PC_next <= PC_reg + 4;
            // branch, PC + offset
            2'b01: PC_next <= PC_reg + pc_branch_offset;
            // jump to ALU_result
            2'b10: PC_next <= ALU_result;
            // jalr, rs1 + offset
            2'b11: PC_next <= ALU_result;
            default: PC_next <= PC_reg + 4; // NO OPERATION
        endcase
    end
endmodule   