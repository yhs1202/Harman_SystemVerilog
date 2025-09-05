`timescale 1ns / 1ps
module tb_count_10000();
    reg clk, rst;
    reg mode;
    reg clear;
    wire [$clog2(10000)-1:0] count;

    counter_10000 uut (
        .clk (clk),
        .rst (rst),
        .i_tick (1'b1),
        .mode (mode), // 0: up, 1: down
        .clear(clear),
        .count_reg (count)
    );

    always #5 clk = ~clk;

    initial begin
        #0; clk = 0; rst = 1; mode = 0; clear = 0;
        #10; rst = 0;
        #1000; mode = 1;
        #1500; clear = 1;
        #10; clear = 0;
        #100; mode = 0;

        #10000;
    $finish;
    end
endmodule
