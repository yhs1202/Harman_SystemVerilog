`timescale 1ns / 1ps
`include "asm2hex_macro.svh"

module ROM (
    input  logic [31:0] addr,
    output logic [31:0] data
);
    logic [31:0] mem[0:2**15-1];
  
    initial begin
        // $readmemh("test_APB_GPI.mem", rom);
        // $readmemh("uart_test.mem", rom);

        if (1) begin
            // I
            // li   x0,  0x0          ; 0 (x0 <= 0x0)
            // li   x3,  0x35         ; 4 (x3 <= 0x35)
            // li   x4,  0x36         ; 8 (x4 <= 0x36)
            mem[0] = ADDI(5'd3, 5'd0, 12'h35);
            mem[1] = ADDI(5'd4, 5'd0, 12'h36);

            // R
            // add  x5,  x3,  x4      ; c (x5 <= 0x35 + 0x36)
            mem[2] = ADD(5'd5, 5'd3, 5'd4);

            // S
            // sw  x3, 12(x0)         ; 10  (RAM[0xC] <= 0x35)
            mem[3] = SW(5'd3, 5'd0, 12'd12);

            // L
            // lw  x6, 12(x0)         ; 14 (x6 <= RAM[0xc] = 0x35)
            mem[4] = LW(5'd6, 5'd0, 12'd12);

            // beq test
            // beq  x5,  x5,  8       ; 18 (branch taken, pc <= pc+8 (0x14))
            // li   x10, x0,  1       ; 1c (skipped)
            // li   x10, x0,  2       ; 20 (branch target, x10 <= 2)
            mem[5] = BEQ(5'd5, 5'd5, 13'd8); // -> branch taken
            mem[6] = ADDI(5'd10, 5'd0, 12'd1); // skipped
            mem[7] = ADDI(5'd10, 5'd0, 12'd2); // *target of branch*

            // LUI, AUIPC
            // lui     x5, 0x12345     ; 24 (x5 <= 0x1234_5000)
            // auipc   x6, 0x1         ; 28 (x6 <= 0x1000 + pc(8))
            mem[8] = LUI(5'd5, 20'h12345);
            mem[9] = AUIPC(5'd6, 20'h1);

            // J
            // jal     x1, 8           ; 2c (x1 <= pc+4 (10), pc <= pc+8 (14))
            // addi    x3, x0, 0x222   ; 30 (skipped)
            // jalr    x2, x1, 6       ; 34 (jal target, x2 <= pc+4(1c), pc <= x0+imm(0, 0x3c))
            // addi    x4, x0, 0x333   ; 38 (skipped)
            // addi    x4, x0, 0x444   ; 3c (jalr target)
            mem[10] = JAL(5'd1, 21'd8);
            mem[11] = JALR(5'd2, 5'd0, 12'd6);
            mem[12] = ADDI(5'd4, 5'd0, 12'h333);
            mem[13] = ADDI(5'd4, 5'd0, 12'h444);
        end



        assign data = mem[addr[31:2]];
    end
endmodule
