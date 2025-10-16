`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    input  logic        regFileWe,
    input  logic        aluSrcMuxSel,
    input  logic [ 3:0] aluControl,
    output logic [31:0] instrMemAddr,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData,
    input logic [2:0] RFWDSrcMuxSel,
    input logic branch,
    input logic jal

);
    logic [31:0] RFData1, RFData2, aluResult;
    logic [31:0] PCOutData, PC_4_AdderResult;
    logic [31:0] immExt, aluSrcMuxOut;
    logic [31:0] RFWDSrcMuxOut;
    logic [31:0] PC_Imm_AdderResult, PCSrcMuxOut;
    logic        PCSrcMuxSel;
    logic        btaken;

    assign instrMemAddr = PCOutData;
    assign busAddr = aluResult;
    assign busWData = RFData2;
    assign PCSrcMuxSel = jal | (btaken & branch);

    RegisterFile U_RegFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (RFWDSrcMuxOut),
        .RD1(RFData1),
        .RD2(RFData2)
    );

    mux_2x1 U_AluSrcMux (
        .sel(aluSrcMuxSel),
        .x0 (RFData2),
        .x1 (immExt),
        .y  (aluSrcMuxOut)
    );

    alu U_ALU (
        .aluControl(aluControl),
        .a         (RFData1),
        .b         (aluSrcMuxOut),
        .result    (aluResult),
        .btaken    (btaken)
    );

    mux_5x1 U_RFWDSrcMux (
        .sel(RFWDSrcMuxSel),
        .x0  (aluSrcMuxOut),
        .x1 (busRData),
        .x2 (immExt),
        .x3 (PC_Imm_AdderResult),
        .x4 (PC_4_AdderResult),
        .y (RFWDSrcMuxOut)
    );

    immExtend U_ImmExtend (
        .instrCode(instrCode),
        .immExt   (immExt)
    );

    adder U_PC_4_Adder (
        .a(32'd4),
        .b(PCOutData),
        .y(PC_4_AdderResult)
    );

    adder U_PC_Imm_Adder (
        .a(immExt),
        .b(PCOutData),
        .y(PC_Imm_AdderResult)
    );

    mux_2x1 U_PCSrcMux (
        .sel(PCSrcMuxSel),
        .x0 (PC_4_AdderResult),
        .x1((instrCode[6:0] == `OP_TYPE_I_JALR) ? aluResult : PC_Imm_AdderResult), // for jalr
        .y  (PCSrcMuxOut)
    );

    register U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (PCSrcMuxOut),
        .q    (PCOutData)
    );

endmodule

module RegisterFile (
    input  logic        clk,
    input  logic        we,
    input  logic [ 4:0] RA1,
    input  logic [ 4:0] RA2,
    input  logic [ 4:0] WA,
    input  logic [31:0] WD,
    output logic [31:0] RD1,
    output logic [31:0] RD2
);
    logic [31:0] mem[0:2**5-1];

    initial begin
        for (int i = 0; i < 32; i++) begin
            mem[i] = i;
        end
    end

    always_ff @(posedge clk) begin
        if (we) mem[WA] <= WD;
    end

    assign RD1 = (RA1 != 0) ? mem[RA1] : 32'b0;
    assign RD2 = (RA2 != 0) ? mem[RA2] : 32'b0;
endmodule

module alu (
    input  logic [ 3:0] aluControl,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] result,
    output logic        btaken
);

    always_comb begin
        result = 32'bx;
        case (aluControl)
            `ADD:  result = a + b;
            `SUB:  result = a - b;
            `SLL:  result = a << b[4:0];
            `SRL:  result = a >> b[4:0];
            `SRA:  result = $signed(a) >>> b[4:0];
            `SLT:  result = ($signed(a) < $signed(b)) ? 1 : 0;
            `SLTU: result = (a < b) ? 1 : 0;
            `XOR:  result = a ^ b;
            `OR:   result = a | b;
            `AND:  result = a & b;
        endcase
    end

    always_comb begin
        case (aluControl[2:0])
            `BEQ: btaken = (a == b);
            `BNE: btaken = (a != b);
            `BLT: btaken = ($signed(a) < $signed(b));
            `BGE: btaken = ($signed(a) >= $signed(b));
            `BLTU: btaken = (a < b);
            `BGEU: btaken = (a >= b);
            default: btaken = 1'b0;
        endcase
    end
endmodule

module register (
    input  logic        clk,
    input  logic        reset,
    input  logic        en,
    input  logic [31:0] d,
    output logic [31:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            q <= 0;
        end else begin
            if (en) q <= d;
        end
    end
endmodule

module adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] y
);
    assign y = a + b;
endmodule

module mux_2x1 (
    input  logic        sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            1'b0: y = x0;
            1'b1: y = x1;
        endcase
    end
endmodule

module mux_5x1 (
    input  logic [2:0]  sel,
    input  logic [31:0] x0,
    input  logic [31:0] x1,
    input  logic [31:0] x2,
    input  logic [31:0] x3,
    input  logic [31:0] x4,
    output logic [31:0] y
);
    always_comb begin
        y = 32'bx;
        case (sel)
            3'b000: y = x0;
            3'b001: y = x1;
            3'b010: y = x2;
            3'b011: y = x3;
            3'b100: y = x4;
            default: y = 32'b0;
        endcase
    end
endmodule

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operator = {instrCode[30], instrCode[14:12]};

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_I, `OP_TYPE_L, `OP_TYPE_I_JALR: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S: immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_B: immExt = {{19{instrCode[31]}}, instrCode[31], instrCode[7], instrCode[30:25], instrCode[11:8], 1'b0};
            `OP_TYPE_U_LUI, `OP_TYPE_U_AUIPC: immExt = {instrCode[31:12], 12'b0};
            `OP_TYPE_J_JAL: immExt = {{11{instrCode[31]}}, instrCode[31], instrCode[19:12], instrCode[20], instrCode[30:21], 1'b0};
            default: immExt = 32'b0;
        endcase
    end
endmodule
