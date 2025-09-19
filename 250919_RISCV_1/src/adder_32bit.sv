`timescale 1ns/1ps

module adder_32bit (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic cin,
    output logic [31:0] sum,
    output logic N, Z, C, V
);
    assign {C, sum} = a + b + cin;
    assign N = sum[31];
    assign Z = (sum == 32'b0);
    assign V = (a[31] == b[31]) && (sum[31] != a[31]);  // Carry in != Carry out for MSB

endmodule