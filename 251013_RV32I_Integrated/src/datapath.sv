`timescale 1ns/1ps
`include "define.svh"

module datapath (
    input logic clk,
    input logic rst,
    input logic [31:0] instr_code,

    // Control Signals
    input logic ALUSrc_A,           // 0: rs1, 1: PC (for AUIPC)
    input logic ALUSrc_B,           // 0: rs2, 1: imm_ext (for I-type, S-type, B-type, U-type)
    input logic RegWrite,
    input logic [31:0] MEM_r_data,
    input logic Branch,
    input logic [1:0] PCSrc,        // 0: PC+4, 1: branch target, 2: jal target, 3: jalr target
    input logic [3:0] ALUControl,
    input logic [1:0] MemtoReg,     // 0: ALU result, 1: memory data, 2: PC+4 (for JAL), 3: imm (for LUI)

    output logic [31:0] ALU_result, // to data memory addr (for store)
    output logic [31:0] MEM_w_data, // to data memory write data (for store)
    output logic branch_taken,
    output logic [31:0] PC
);

    logic [31:0] RD1, RD2;
    logic [31:0] alu_a, alu_b;
    logic N, Z, C, V;
    logic [31:0] REG_w_data;
    logic [31:0] PC_Plus4;
    logic [31:0] imm_ext;

    assign MEM_w_data = RD2;
    // 0: rs1, 1: PC (for AUIPC)
    assign alu_a = (ALUSrc_A) ? PC : RD1;
    // 0: rs2, 1: imm_ext (for I-type, S-type, B-type, U-type)
    assign alu_b = (ALUSrc_B) ? imm_ext : RD2;

    // 
    assign REG_w_data = (MemtoReg == 2'b00) ? ALU_result : // for R-type, I-type, AUIPC
                            (MemtoReg == 2'b01) ? MEM_r_data : // for load
                            (MemtoReg == 2'b10) ? PC_Plus4 :   // for JAL
                            imm_ext; // for LUI

    
    regfile U_REGFILE (
        .clk (clk),
        .w_en (RegWrite),
        .RA1 (instr_code[19:15]),
        .RA2 (instr_code[24:20]),
        .WA (instr_code[11:7]),
        .WD (REG_w_data),

        .RD1 (RD1),
        .RD2 (RD2)
    );

    ALU_32bit U_ALU_32bit (
        .ALUControl (ALUControl),
        .a(alu_a),
        .b(alu_b),
        .N(N),
        .Z(Z),
        .C(C),
        .V(V),

        .ALU_result (ALU_result)
    );

    extend U_EXTEND (
        .instr_code (instr_code),
        .imm_ext (imm_ext)
    );

    PC_logic U_PC_LOGIC (
        .clk (clk),
        .rst (rst),
        .PC_imm_offset (imm_ext),
        .ALU_result (ALU_result),
        .PCSrc (PCSrc),

        .PC_Plus4 (PC_Plus4),
        .PC_reg (PC)
    );

    branch_logic U_BRANCH_LOGIC (
        .Branch (Branch),
        .N (N),
        .Z (Z),
        .C (C),
        .V (V),
        .func3 (instr_code[14:12]),

        .branch_taken (branch_taken)
    );
endmodule


module regfile (
    input logic clk,
    input logic w_en,
    input logic [4:0] RA1,
    input logic [4:0] RA2,
    input logic [4:0] WA,
    input logic [31:0] WD,

    output logic [31:0] RD1,
    output logic [31:0] RD2
);

    logic [31:0] mem [0:31];

    always_ff @( posedge clk ) begin
        if (w_en) begin
            mem[WA] <= WD;
        end
    end

    always_comb begin
        RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
        RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
    end

    initial begin
        for (int i = 0; i<32; i++) begin
            mem[i] = 32'd0;
        end
    end

endmodule


module ALU_32bit (
    input logic [3:0] ALUControl,
    input logic signed [31:0] a,
    input logic signed [31:0] b,

    output logic N, Z, C, V,
    output logic [31:0] ALU_result
);

    assign N = ALU_result[31];
    assign Z = (ALU_result == 32'b0);

    always_comb begin : ALU_operations
        C = 1'b0; V = 1'b0;
        case (ALUControl)
            `ALU_ADD: begin
                {C, ALU_result} = a + b;
                V = (~(a[31]^b[31]) & (a[31]^ALU_result[31]));
            end
            `ALU_SUB: begin
                {C, ALU_result} = a - b;    // C = ~borrow
                V = ((a[31]^b[31]) & (a[31]^ALU_result[31]));
            end
            `ALU_XOR: ALU_result = a ^ b;
            `ALU_OR: ALU_result = a | b;
            `ALU_AND: ALU_result = a & b;
            `ALU_SLL: ALU_result = a << b[4:0];
            `ALU_SRL: ALU_result = a >> b[4:0];
            `ALU_SRA: ALU_result = $signed(a) >>> b[4:0];
            `ALU_SLT: ALU_result = {31'b0, $signed(a) < $signed(b)};
            `ALU_SLTU: ALU_result = {31'b0, $unsigned(a) < $unsigned(b)};
            default: ALU_result = 32'bx;    // NO OPERATION
        endcase
    end
endmodule

module extend (
    input logic [31:0] instr_code,
    output logic [31:0] imm_ext
);

    wire [6:0] opcode = instr_code[6:0];
    wire [2:0] func3 = instr_code[14:12];

    always_comb begin
        case (opcode)
            `OP_I_LOAD, `OP_I_JALR: begin // I-type
                imm_ext = {{20{instr_code[31]}}, instr_code[31:20]};
            end
            `OP_I_ARITH: begin
                case (func3)
                    3'b001, 3'b101: begin // SLLI, SRLI, SRAI
                        imm_ext = {27'b0, instr_code[24:20]}; // zero-extend for shift amount
                    end 
                    default: imm_ext = {{20{instr_code[31]}}, instr_code[31:20]}; // sign-extend for other I-type
                endcase
            end
            `OP_S: begin // S-type
                imm_ext = {{20{instr_code[31]}}, instr_code[31:25], instr_code[11:7]};
            end
            `OP_B: begin // B-type
                imm_ext = {{19{instr_code[31]}}, instr_code[31], instr_code[7], instr_code[30:25], instr_code[11:8], 1'b0};   // Shift left by 1
            end
            `OP_U_LUI, `OP_U_AUIPC: begin // U-type
                imm_ext = {instr_code[31:12], 12'b0};
            end
            `OP_J_JAL: begin // J-type
                imm_ext = {{11{instr_code[31]}}, instr_code[31], instr_code[19:12], instr_code[20], instr_code[30:21], 1'b0}; // Shift left by 1
            end
            default: begin
                imm_ext = 32'bx; // Default case to avoid latches
            end
        endcase
    end
endmodule

module PC_logic (
    input logic clk,
    input logic rst,
    input logic [31:0] PC_imm_offset,   // imm extended value
    input logic [31:0] ALU_result,
    input logic [1:0] PCSrc,            // 0:pc+4, 1:branch, 2: jump, 3: jalr

    output logic [31:0] PC_Plus4,       // for jal
    output logic [31:0] PC_reg
);

    logic [31:0] PC_next;
    assign PC_Plus4 = PC_reg + 32'd4;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            PC_reg <= 32'h0000_0000;
        end else begin
            PC_reg <= PC_next;
        end
    end

    always_comb begin
        case (PCSrc)
            // PC + 4
            2'b00: PC_next = PC_reg + 32'd4;
            // branch -> PC + offset
            2'b01: PC_next = PC_reg + PC_imm_offset;
            // JAL -> PC + offset
            2'b10: PC_next = PC_reg + PC_imm_offset;
            // JALR -> ALU result
            2'b11: PC_next = ALU_result & 32'hFFFF_FFFE; // (rs1 + imm) & ~1
        endcase
    end
endmodule

module branch_logic (
    input logic Branch,
    input logic N, Z, C, V,
    input logic [2:0] func3,

    output logic branch_taken
);
    always_comb begin
        if (Branch) begin
            case (func3)
                `F3_BEQ: branch_taken = Z;
                `F3_BNE: branch_taken = ~Z;
                `F3_BLT: branch_taken = N ^ V;
                /* 
                Signed less than: if N and V are different, it means branch is taken. (see below)
                   ex)  rs1         rs2       branch_taken      rs1-rs2       N     V    N^V
                   ------------   -------    --------------  -------------  ----- ----- ------
                        10          20        should be 1       -10           1     0     1
                        20          10        should be 0        10           0     0     0
                       -10         -20        should be 1        10           0     1     1
                       -20         -10        should be 0       -10           1     1     0
                    0x7FFF_FFFF  0xFFFF_FFFF  should be 0    0x8000_0000     "1"    1     0 (overflow)
                   (+2147483647)   (-1)                     (-2147483648)    // the reason branch_taken for blt is N^V, not just N
                */
                `F3_BGE: branch_taken = ~(N ^ V);
                `F3_BLTU: branch_taken = ~C;
                /*
                Unsigned less than: if there is borrow (~C) in rs1 - rs2, it means rs1 < rs2, so branch is taken.
                borrow -> occurs when the minuend (rs1) is less than the subtrahend (rs2), 
                rs1 - rs2 = rs1 + (~rs2 + 1), 
                   ex)  rs1         rs2       branch_taken      rs1-rs2      C    ~C
                   ------------   -------    --------------  -------------  ---- -----
                        10          20        should be 1       -10          0     1
                        20          10        should be 0        10          1     0
                       -10         -20        should be 0        10          1     0
                       -20         -10        should be 1       -10          0     1
                    0x0000_0000  0xFFFF_FFFF  should be 1    0x0000_0001     0     1 (borrow)
                       (0)      (4294967295)  should be 1   (-4294967295)   "0"    1 (borrow)
                */
                `F3_BGEU: branch_taken = C;
                default: branch_taken = 1'b0;
            endcase
        end else begin
            branch_taken = 1'b0; // No branch
        end
    end
endmodule