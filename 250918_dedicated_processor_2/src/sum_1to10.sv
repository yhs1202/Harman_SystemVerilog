`timescale 1ns/1ps
module sum_1to10 (
    input logic clk,
    input logic rst,
    output logic [7:0] out
);
    logic sumSrcSel;
    logic iSrcSel;
    logic sumLoad;
    logic iLoad;
    logic adderSrcSel;
    logic OutLoad;

    logic iLe10;

    sum_1to10_cu U_CONTROL_UNIT (
        .*,
        .not_iLe10 (iLe10)
    );

    sum_1to10_datapath U_DATAPATH (
        .*,
        .not_iLe10 (iLe10),
        .out (out)
    );
endmodule