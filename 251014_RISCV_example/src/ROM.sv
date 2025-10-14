`timescale 1ns / 1ps

module ROM (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:2**8-1];

    initial begin
        //rom[x]=32'b   f7  _ rs2 _ rs1 _ f3_ rd  _ opcode;// R-Type
        rom[0] = 32'b0000000_00001_00010_000_00100_0110011;// add x4, x2, x1
        rom[1] = 32'b0100000_00001_00010_000_00101_0110011;// sub x5, x2, x1
        rom[2] = 32'b0000000_00000_00011_111_00110_0110011;// and x6, x3, x0
        rom[3] = 32'b0000000_00000_00011_110_00111_0110011;// or  x7, x3, x0
        //rom[x]=32'b   imm      _ rs1 _ f3_ rd  _ opcode; // I-Type
        rom[4] = 32'b000000000001_00001_000_01001_0010011;// addi x9, x1, 1;
        rom[5] = 32'b000000000100_00010_111_01010_0010011;// andi x10, x2, 4;
        rom[6] = 32'b000000000011_00001_001_01011_0010011;// slli x11, x1, 3;
    end

    assign data = rom[addr[31:2]];
endmodule
