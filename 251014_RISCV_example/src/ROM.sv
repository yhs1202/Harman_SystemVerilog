`timescale 1ns / 1ps
`include "asm2hex_macro.svh"

module ROM (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] rom[0:2**8-1];

    initial begin
        //rom[x]=32'b   f7  _ rs2 _ rs1 _ f3_ rd  _ opcode;// R-Type
        //rom[0] = 32'b0000000_00001_00010_000_00100_0110011;// add x4, x2, x1
        //rom[1] = 32'b0100000_00001_00010_000_00101_0110011;// sub x5, x2, x1
        //rom[2] = 32'b0000000_00000_00011_111_00110_0110011;// and x6, x3, x0
        //rom[3] = 32'b0000000_00000_00011_110_00111_0110011;// or  x7, x3, x0
        ////rom[x]=32'b   imm      _ rs1 _ f3_ rd  _ opcode; // I-Type
        //rom[4] = 32'b000000000001_00001_000_01001_0010011;// addi x9, x1, 1;
        //rom[5] = 32'b000000000100_00010_111_01010_0010011;// andi x10, x2, 4;
        //rom[6] = 32'b000000000011_00001_001_01011_0010011;// slli x11, x1, 3;

        /*
        // addi x1, x0, 5
        rom[0] = ADDI(5'd5, 5'd0, 12'd5);
        // addi x2, x0, 10
        rom[1] = ADDI(5'd10, 5'd0, 12'd10);
        // addi x3, x0, 15
        rom[2] = ADDI(5'd15, 5'd0, 12'd15);

        // add x4, x2, x1
        rom[3] = ADD(5'd4, 5'd2, 5'd1);
        // sub x5, x2, x1
        rom[4] = SUB(5'd5, 5'd2, 5'd1);
        // and x6, x3, x0
        rom[5] = AND(5'd6, 5'd3, 5'd0);
        // or  x7, x3, x0
        rom[6] = OR(5'd7, 5'd3, 5'd0);

        // addi x9, x1, 1
        rom[7] = ADDI(5'd9, 5'd1, 12'd1);
        // andi x10, x2, 4
        rom[8] = ANDI(5'd10, 5'd2, 12'd4);
        // slli x11, x1, 3
        rom[9] = SLLI(5'd11, 5'd1, 5'd3);
        // slli x12, x1, 9
        rom[10] = SLLI(5'd12, 5'd1, 5'd9);
        // slli x13, x1, 30
        rom[11] = SLLI(5'd13, 5'd1, 5'd30);

        // sb x11, 4(x0)
        rom[12] = SB(5'd11, 5'd0, 12'd4);
        // sh x12, 8(x0)
        rom[13] = SH(5'd12, 5'd0, 12'd8);
        // sw x13, 12(x0)
        rom[14] = SW(5'd13, 5'd0, 12'd12);
        */

     /* S, I_load test scenario in asm code
        ; S-type (store)
        li  x1, 0x12345678  ; 0,4 (x1 <= 0x1234_5678)
        sb  x1, 4(x0)       ; 8 (RAM[0x4] <= 0x78)
        sh  x1, 8(x0)       ; c (RAM[0x8] <= 0x5678)
        sw  x1, 12(x0)      ; 10 (RAM[0xC] <= 0x1234_5678)

        ; I-type (load)
        lb  x4, 4(x0)       ; 14 (x4 <= RAM[0x4] = 0x78)
        lh  x5, 8(x0)       ; 18 (x5 <= RAM[0x8] = 0x5678)
        lw  x6, 12(x0)      ; 1c (x6 <= RAM[0xc] = 0x1234_5678)


        ; lbu, lhu test
        li  x1, 0xFFFF_FF80 ; 20, 24 (x1 <= 0xFFFF_FF80)
        li  x2, 0xc         ; 28 (x2 <= 0xc, base RAM addr)

        sb  x1, 4(x2)       ; 2c (RAM[0x10] <= 0x80)
        lb  x7, 4(x2)       ; 30 (x7 <= 0xFFFF_FF80, -128)
        lbu x8, 4(x2)       ; 34 (x8 <= 0x0000_0080, +128)

        li  x1, 0xFFFF_8000 ; 38 (x1 <= 0xFFFF_8000)

        sh  x1, 8(x2)       ; 3c (RAM[0x14] <= 0x8000)
        lh  x9, 8(x2)       ; 40 (x9 <= 0xFFFF8000, -32768)
        lhu x10, 8(x2)      ; 44 (x9 <= 0x8000, +32768)
    */

        rom[0] = LUI(5'd1, 20'h12345);
        rom[1] = ADDI(5'd1, 5'd1, 12'h678);
        rom[2] = SB(5'd1, 5'd0, 12'd4);
        rom[3] = SH(5'd1, 5'd0, 12'd8);
        rom[4] = SW(5'd1, 5'd0, 12'd12);

        rom[5] = LB(5'd4, 5'd0, 12'd4);
        rom[6] = LH(5'd5, 5'd0, 12'd8);
        rom[7] = LW(5'd6, 5'd0, 12'd12);

        rom[8] = LUI(5'd1, 20'hFFFFF);
        rom[9] = ADDI(5'd1, 5'd0, 12'hF80);
        rom[10] = ADDI(5'd2, 5'd0, 12'hC);

        rom[11] = SB(5'd1, 5'd2, 12'd4);
        rom[12] = LB(5'd7, 5'd2, 12'd4);
        rom[13] = LBU(5'd8, 5'd2, 12'd4);

        rom[14] = LUI(5'd1, 20'hFFFF8);
        rom[15] = SH(5'd1, 5'd2, 12'd8);
        rom[16] = LH(5'd9, 5'd2, 12'd8);
        rom[17] = LHU(5'd10, 5'd2, 12'd8);


        end

    assign data = rom[addr[31:2]];
endmodule
