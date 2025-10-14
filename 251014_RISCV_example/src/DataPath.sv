`timescale 1ns / 1ps
`include "defines.sv"

module DataPath (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    input  logic        regFileWe,
    input  logic        aluSrcMuxSel,
    input  logic [ 3:0] aluControl,
    input  logic  [1:0] MemtoReg_Sel,

    output logic [31:0] instrMemAddr,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData

);
    logic [31:0] RFData1, RFData2, aluResult;
    logic [31:0] PCOutData, PC_4_AdderResult;
    logic [31:0] immExt, aluSrcMuxOut;

    wire [31:0] MemtoReg_Data = (MemtoReg_Sel == 2'b00) ? aluResult :
                                (MemtoReg_Sel == 2'b01) ? busRData :
                                (MemtoReg_Sel == 2'b10) ? PC_4_AdderResult : 
                                (MemtoReg_Sel == 2'b11) ? immExt : 32'b0;

    assign instrMemAddr = PCOutData;
    assign busAddr      = aluResult;
    assign busWData     = RFData2;

    RegisterFile U_RegFile (
        .clk(clk),
        .we (regFileWe),
        .RA1(instrCode[19:15]),
        .RA2(instrCode[24:20]),
        .WA (instrCode[11:7]),
        .WD (MemtoReg_Data),
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
        .result    (aluResult)
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

    register U_PC (
        .clk  (clk),
        .reset(reset),
        .en   (1'b1),
        .d    (PC_4_AdderResult),
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
    output logic [31:0] result
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

module immExtend (
    input  logic [31:0] instrCode,
    output logic [31:0] immExt
);
    wire [6:0] opcode = instrCode[6:0];
    wire [3:0] operator = {instrCode[30], instrCode[14:12]};

    always_comb begin
        immExt = 32'bx;
        case (opcode)
            `OP_TYPE_I: 
                case (instrCode[14:12])
                    // SLLI, SRLI, SRAI
                    3'b001, 3'b101: immExt = {27'b0, instrCode[24:20]}; // zero-extend for shift instructions
                    default: immExt = {{20{instrCode[31]}}, instrCode[31:20]}; // sign-extend for other I-type instructions
                endcase
            `OP_TYPE_I_LOAD: immExt = {{20{instrCode[31]}}, instrCode[31:20]};
            `OP_TYPE_S: immExt = {{20{instrCode[31]}}, instrCode[31:25], instrCode[11:7]};
            `OP_TYPE_U_LUI: immExt = {instrCode[31:12], 12'b0};

            default: immExt = 32'b0;
            
        endcase
    end
endmodule
