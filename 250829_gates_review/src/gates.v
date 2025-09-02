`timescale 1ns / 1ps
module gates(
    input a,
    input b,
    output z0, z1, z2, z3, z4, z5
);
    assign z0 = a & b;
    assign z1 = ~(a & b);
    assign z2 = a | b;
    assign z3 = ~(a | b);
    assign z4 = a ^ b;
    assign z5 = ~b;
endmodule
