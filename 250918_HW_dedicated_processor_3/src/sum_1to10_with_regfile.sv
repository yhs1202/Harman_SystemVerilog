`timescale 1ns/1ps
module sum_1to10_with_regfile (
    input logic clk,
    input logic rst,
    output logic [7:0] out
);

    logic [1:0] r_addr_0, r_addr_1;
    logic R1SrcSel, w_en, OutLoad;
    logic [1:0] w_addr;
    logic iLe10;

    sum_1to10_with_regfile_cu U_CONTROL_UNIT (
        .*,
        .iLe10 (iLe10),

        .R1SrcSel (R1SrcSel),
        .r_addr_0 (r_addr_0),
        .r_addr_1 (r_addr_1),
        .w_en (w_en),
        .w_addr (w_addr),
        .OutLoad (OutLoad)
    );

    sum_1to10_with_regfile_datapath U_DATAPATH (
        .*,
        .R1SrcSel (R1SrcSel),
        .r_addr_0 (r_addr_0),
        .r_addr_1 (r_addr_1),
        .w_en (w_en),
        .w_addr (w_addr),
        .OutLoad (OutLoad),
        
        .iLe10 (iLe10),
        .out (out)
    );
endmodule



// `timescale 1ns/1ps
// module sum_1to10_with_regfile (
//     input logic clk,
//     input logic rst,
//     output logic [7:0] out
// );
//     logic iLe10;

//     logic [1:0] r_addr_0, r_addr_1;

//     sum_1to10_with_regfile_cu U_CONTROL_UNIT (
//         .*,
//         .r_addr_0 (r_addr_0),
//         .r_addr_1 (r_addr_1),
//         .not_iLe10 (iLe10)
//     );

//     sum_1to10_with_regfile_datapath U_DATAPATH (
//         .*,
//         .r_addr_0 (r_addr_0),
//         .r_addr_1 (r_addr_1),
//         .not_iLe10 (iLe10),
//         .out (out)
//     );
// endmodule