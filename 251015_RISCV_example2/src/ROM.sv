`timescale 1ns / 1ps
`include "asm2hex_macro.svh"

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
        rom[7] = 32'b000000001001_00001_001_01100_0010011;// slli x12, x1, 9;
        rom[8] = 32'b000000011110_00001_001_01101_0010011;// slli x13, x1, 30;
        //rom[x]=32'b imm(7)_ rs2 _ rs1 _ f3_imm5 _ opcode; // S-Type
        rom[9] = BEQ(5'd2, 5'd2, 12'd8); // beq x2, x2, 8
        rom[10] = 32'b0000000_01011_00000_000_00100_0100011;// sb x11, 4(x0);
        rom[11] = 32'b0000000_01100_00000_001_01000_0100011;// sh x12, 8(x0);
        rom[12] = 32'b0000000_01101_00000_010_01100_0100011;// sw x13, 12(x0);

        rom[13] = LB(5'd14, 5'd0, 12'd4); // lb x14, 4(x0);
        rom[14] = LH(5'd15, 5'd0, 12'd8); // lh x15, 8(x0);
        rom[15] = LW(5'd16, 5'd0, 12'd12);// lw x16, 12(x0);

        rom[16] = LUI(5'd17, 20'h10000);        // lui x17, 0x10000;
        rom[17] = AUIPC(5'd18, 20'h10000);      // auipc x18, 0x10000;
        rom[18] = JAL(5'd19, 20'd8);            // jal x19, 8;
        rom[19] = ADDI(5'd20, 5'd0, 12'h222);   // addi x20, x0, 0;   // skipped by jal
        rom[20] = JALR(5'd21, 5'd0, 12'h58);    // jalr x20, 0(x0);    // jal target
        rom[21] = ADDI(5'd22, 5'd0, 12'h333);   // addi x22, x0, 0;   // skipped by jalr
        rom[22] = ADDI(5'd23, 5'd0, 12'h444);   // addi x23, x0, 0;   // jalr target

    end

    assign data = rom[addr[31:2]];
endmodule
