`timescale 1ns / 1ps
module tb_counter ();
    reg clk, rst;
    wire [3:0] count;

    counter uut (
        .clk  (clk),
        .rst  (rst),
        .count_reg(count)
    );

    always #10 clk = ~clk;
    initial begin
        #0 clk = 0;
        rst = 1;
        #10 rst = 0;
        #1000
        $finish;
    end
endmodule
