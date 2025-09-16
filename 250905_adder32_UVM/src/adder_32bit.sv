`timescale 1ns / 1ps
module adder_32bit(
    input logic [31:0] a, b,
    output logic [31:0] sum,
    output logic carry
    );

    // assign sum = a + b;
    // assign carry = (a + b) > 32'hFFFFFFFF ? 1 : 0;
    assign {sum, carry} = a + b;
endmodule
