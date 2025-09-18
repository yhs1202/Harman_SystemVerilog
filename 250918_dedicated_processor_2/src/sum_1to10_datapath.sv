`timescale 1ns / 1ps
module sum_1to10_datapath (
    input logic clk,
    input logic rst,
    input logic sumSrcSel,
    input logic iSrcSel,
    input logic sumLoad,
    input logic iLoad,
    input logic adderSrcSel,
    input logic OutLoad,

    output logic not_iLe10,
    output logic [7:0] out
);

    logic [7:0] sum_mux_out;
    logic [7:0] i_mux_out;
    logic [7:0] sum_reg_out;
    logic [7:0] i_reg_out;
    logic [7:0] adderSrc_mux_out;
    logic [7:0] adder_out;

    // Instantiate modules
    mux_2x1 U_MUX_SUMSRC (
        .sel (sumSrcSel),
        .in0 (8'b0),
        .in1 (adder_out),
        .out (sum_mux_out)
    );

    mux_2x1 U_MUX_ISRC (
        .sel (iSrcSel),
        .in0 (8'b0),
        .in1 (adder_out),
        .out (i_mux_out)
    );

    Register U_SUM_REG (
        .*,
        .Load_en (sumLoad),
        .d (sum_mux_out),
        .q (sum_reg_out)
    );

    Register U_I_REG (
        .*,
        .Load_en (iLoad),
        .d (i_mux_out),
        .q (i_reg_out)
    );

    Comparator U_COMPARATOR (
        .a(8'd10),
        .b(i_reg_out),
        .slt(not_iLe10)
    );

    mux_2x1 U_MUX_ADDERSRC (
        .sel (adderSrcSel),
        .in0 (sum_reg_out),
        .in1 (8'b1),
        .out (adderSrc_mux_out)
    );


    Adder U_ADDER (
        .a (adderSrc_mux_out),
        .b (i_reg_out),
        .sum (adder_out)
    );

    Register U_OUTREG (
        .*,
        .Load_en (OutLoad),
        .d (sum_reg_out),
        .q (out)
    );


    
endmodule



// 2x1 MUX
module mux_2x1 (
    input logic sel,
    input logic [7:0] in0,
    input logic [7:0] in1,
    output logic [7:0] out
);
    always_comb begin
        out = 8'b0;
        if (sel) out = in1;
        else out = in0;
    end

endmodule


// Register with load enable
module Register (
    input logic clk,
    input logic rst,
    input logic Load_en,
    input logic [7:0] d,
    output logic [7:0] q
);

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            q <= 0;
        end else begin
            if (Load_en) begin
                q <= d;
            end
        end
    end
endmodule


// Comparator for two 8-bit numbers
// !!!!!!!!!! Should be inversion in this case (i <= 10 -> !(10 < i)) !!!!!!!!!!!!!!!!!!!
module Comparator (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic slt
);
    assign slt = (a < b) ? 1'b1 : 1'b0;

endmodule


// adder for two 8-bit numbers
module Adder (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] sum
);
    assign sum = a + b;

endmodule