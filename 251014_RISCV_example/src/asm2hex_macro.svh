`include "defines.sv"

// RV32I Instruction Macros
// Use: INSTRUCTION_MACRO_NAME([4:0] rd, [4:0] rs1, [4:0] rs2 / [11(I_a)/11(I_l)/12(S)/19(B)/20():0]imm / [4:0] shamt)

    /* ---------- R-type ----------
    add rd, rs1, rs2
        (5) (5)  (5)
    func7, rs2, rs1, func3, rd, opcode
     (7)   (5)  (5)   (3)  (5)   (7)
    */
    function automatic [31:0] ADD (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b000, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] SUB (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0100000, rs2, rs1, 3'b000, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] XOR (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b100, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] OR  (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b110, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] AND (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b111, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] SLL (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b001, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] SRL (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b101, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] SRA (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0100000, rs2, rs1, 3'b101, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] SLT (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b010, rd, `OP_TYPE_R};
    endfunction

    function automatic [31:0] SLTU (input [4:0] rd, input [4:0] rs1, input [4:0] rs2);
        return {7'b0000000, rs2, rs1, 3'b011, rd, `OP_TYPE_R};
    endfunction



    /* ---------- I-type (arith) ----------
    addi rd, rs1, imm
        (5) (5)   (12)
    imm, rs1, func3, rd, opcode
    (12) (5)   (3)   (5)  (7)
    */
    function automatic [31:0] ADDI (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b000, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] XORI (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b100, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] ORI  (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b110, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] ANDI (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b111, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] SLLI (input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return {7'b0000000, shamt, rs1, 3'b001, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] SRLI (input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return {7'b0000000, shamt, rs1, 3'b101, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] SRAI (input [4:0] rd, input [4:0] rs1, input [4:0] shamt);
        return {7'b0100000, shamt, rs1, 3'b101, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] SLTI (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b010, rd, `OP_TYPE_I};
    endfunction

    function automatic [31:0] SLTIU (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b011, rd, `OP_TYPE_I};
    endfunction

    /* ---------- I-type (load) ----------
    lw rd, imm(rs1)
      (5)  (12)(5)
    imm, rs1, func3, rd, opcode
    (12) (5)   (3)   (5)  (7)
    */
    function automatic [31:0] LB (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b000, rd, `OP_TYPE_I_LOAD};
    endfunction

    function automatic [31:0] LH (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b001, rd, `OP_TYPE_I_LOAD};
    endfunction

    function automatic [31:0] LW (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b010, rd, `OP_TYPE_I_LOAD};
    endfunction

    function automatic [31:0] LBU (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b100, rd, `OP_TYPE_I_LOAD};
    endfunction

    function automatic [31:0] LHU (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b101, rd, `OP_TYPE_I_LOAD};
    endfunction

    /* ---------- S-type (store) ----------
    sw rs2, imm(rs1)
       (5)  (12) (5)
    imm[11:5], rs2, rs1, func3, imm[4:0], opcode
       (7)     (5)  (5)   (3)     (5)      (7)
    */
    function automatic [31:0] SB (input [4:0] rs2, input [4:0] rs1, input [11:0] imm);
        return {imm[11:5], rs2, rs1, 3'b000, imm[4:0], `OP_TYPE_S};
    endfunction

    function automatic [31:0] SH (input [4:0] rs2, input [4:0] rs1, input [11:0] imm);
        return {imm[11:5], rs2, rs1, 3'b001, imm[4:0], `OP_TYPE_S};
    endfunction

    function automatic [31:0] SW (input [4:0] rs2, input [4:0] rs1, input [11:0] imm);
        return {imm[11:5], rs2, rs1, 3'b010, imm[4:0], `OP_TYPE_S};
    endfunction

    /* ---------- B-type (branch) ----------
    beq rs1, rs2, imm
       (5)  (5)   (13)
    imm[12], imm[10:5], rs2, rs1, func3, imm[4:1], imm[11], opcode
      (1)       (6)     (5)  (5)   (3)     (4)       (1)     (7)
    */
    function automatic [31:0] BEQ (input [4:0] rs1, input [4:0] rs2, input [12:0] imm);
        return {imm[12], imm[10:5], rs2, rs1, 3'b000, imm[4:1], imm[11], `OP_TYPE_B};
    endfunction

    function automatic [31:0] BNE (input [4:0] rs1, input [4:0] rs2, input [12:0] imm);
        return {imm[12], imm[10:5], rs2, rs1, 3'b001, imm[4:1], imm[11], `OP_TYPE_B};
    endfunction

    function automatic [31:0] BLT (input [4:0] rs1, input [4:0] rs2, input [12:0] imm);
        return {imm[12], imm[10:5], rs2, rs1, 3'b100, imm[4:1], imm[11], `OP_TYPE_B};
    endfunction

    function automatic [31:0] BGE (input [4:0] rs1, input [4:0] rs2, input [12:0] imm);
        return {imm[12], imm[10:5], rs2, rs1, 3'b101, imm[4:1], imm[11], `OP_TYPE_B};
    endfunction

    function automatic [31:0] BLTU (input [4:0] rs1, input [4:0] rs2, input [12:0] imm);
        return {imm[12], imm[10:5], rs2, rs1, 3'b110, imm[4:1], imm[11], `OP_TYPE_B};
    endfunction

    function automatic [31:0] BGEU (input [4:0] rs1, input [4:0] rs2, input [12:0] imm);
        return {imm[12], imm[10:5], rs2, rs1, 3'b111, imm[4:1], imm[11], `OP_TYPE_B};
    endfunction

    /* ---------- U-type ----------
    auipc rd, imm
        (5) (20)
    imm, rd, opcode
    (20) (5)  (7)
    */
    function automatic [31:0] LUI (input [4:0] rd, input [19:0] imm);
        return {imm, rd, `OP_TYPE_U_LUI};
    endfunction

    function automatic [31:0] AUIPC (input [4:0] rd, input [19:0] imm);
        return {imm, rd, `OP_TYPE_U_AUIPC};
    endfunction

    /* ---------- J-type ----------
    jal rd, imm
       (5)  (20)
    imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode
      (1)      (10)       (1)       (8)      (5)  (7)

    jalr rd, rs1, imm
        (5)  (5)  (12)
    imm, rs1, func3, rd, opcode
    (12) (5)   (3)   (5)  (7)
    */
    function automatic [31:0] JAL (input [4:0] rd, input [20:0] imm);
        return {imm[20], imm[10:1], imm[11], imm[19:12], rd, `OP_TYPE_J_JAL};
    endfunction

    function automatic [31:0] JALR (input [4:0] rd, input [4:0] rs1, input [11:0] imm);
        return {imm, rs1, 3'b000, rd, `OP_TYPE_I_JALR};
    endfunction

    // ---------- SYSTEM ----------
    function automatic [31:0] ECALL ();
        return {12'h000, 5'd0, 3'b000, 5'd0, 7'b1110011};
    endfunction

    function automatic [31:0] EBREAK ();
        return {12'h001, 5'd0, 3'b000, 5'd0, 7'b1110011};
    endfunction