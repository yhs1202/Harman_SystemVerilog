`timescale 1ns / 1ps

module CPU_RV32I (
    input  logic        clk,
    input  logic        reset,
    input  logic [31:0] instrCode,
    output logic [31:0] instrMemAddr,
    output logic [ 2:0] strb,
    output logic        busWe,
    output logic [31:0] busAddr,
    output logic [31:0] busWData,
    input  logic [31:0] busRData
);

    logic       regFileWe;
    logic       aluSrcMuxSel;
    logic [3:0] aluControl;
    logic [3:0] RFWDSrcMuxSel;
    logic       branch;
    logic       jal;

    ControlUnit U_ControlUnit (.*);
    DataPath U_DataPath (.*);

endmodule
