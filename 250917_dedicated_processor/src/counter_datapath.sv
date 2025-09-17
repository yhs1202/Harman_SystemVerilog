`timescale 1ns / 1ps

module counter_datapath (
    input logic clk,
    input logic rst,
    input logic AsrcSel,
    input logic ALoad,
    input logic OutBufSel,
    output logic ALt10,
    output logic [7:0] out
);

    logic [7:0] Areg_out;
    logic [7:0] mux_out;
    logic [7:0] adder_out;

    // Instantiate modules
    mux_2x1 U_MUX_2X1 (
        .sel(AsrcSel),
        .in0(8'b0),          // Constant 0
        .in1(adder_out),     // Output of the adder
        .out(mux_out)
    );

    Areg U_A_REG (
        .clk(clk),
        .rst(rst),
        .ALoad(ALoad),
        .d(mux_out),
        .q(Areg_out)
    );

    Comparator U_COMPARATOR (
        .a(Areg_out),
        .b(8'd10),           // Compare with 10
        .slt(ALt10)
    );

    Adder U_ADDER (
        .a(Areg_out),
        .b(8'b1),            // Increment by 1
        .sum(adder_out)
    );

    OutBuf U_OUTBUF (
        .in(Areg_out),
        .OutBufSel(OutBufSel),
        .out(out)
    );



endmodule


// 2x1 MUX for AsrcSel
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
module Areg (
    input logic clk,
    input logic rst,
    input logic ALoad,
    input logic [7:0] d,
    output logic [7:0] q
);

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            q <= 0;
        end else begin
            if (ALoad) begin
                q <= d;
            end
        end
    end
endmodule


// Comparator for two 8-bit numbers
module Comparator (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic slt
);
    assign slt = a < b;  

endmodule


// adder for two 8-bit numbers
module Adder (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] sum
);
    assign sum = a + b;

endmodule


// output buffer with enable
module OutBuf (
    input logic [7:0] in,
    input logic OutBufSel,
    output logic [7:0] out
);
    assign out = OutBufSel ? in : 8'bz;

endmodule