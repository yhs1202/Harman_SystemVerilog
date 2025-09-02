`timescale 1ns / 1ps
module tb_count_10000();
    reg clk, rst;
    reg mode;
    reg enable, clear;
    wire [$clog2(10000)-1:0] count;

    counter_10000 uut (
        .clk (clk),
        .rst (rst),
        .mode (mode), // 0: down, 1: up
        .count_reg (count)
    );

    always #5 clk = ~clk;

    initial begin
        #0 clk=0; rst=1; mode=1; enable=1; clear=0;
        #10 rst=0;

        #100000
    $finish;
    end
endmodule
