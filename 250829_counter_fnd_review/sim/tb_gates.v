`timescale 1ns / 1ps
module tb_gates();
    reg a, b;
    wire z0, z1, z2, z3, z4, z5;
    gates uut (
        .a(a),
        .b(b),
        .z0(z0),
        .z1(z1),
        .z2(z2),
        .z3(z3),
        .z4(z4),
        .z5(z5)
    );
    initial begin
        a=0; b=0;
        #10 a=0; b=1;
        #10 a=1; b=0;
        #10 a=1; b=1;
        #10 $finish;

    end
endmodule