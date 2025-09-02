`timescale 1ns / 1ps
module tb_clk_div();
    reg clk, rst;
    wire clk_out;

    clk_div U_CLK_DIV (
        .clk (clk),
        .rst (rst),
        .clk_out (clk_out)
    );

    always #5 clk = ~clk;
    initial begin
        #0 clk=0; rst=1;
        #10 rst=0;
        #1000
        $finish;
    end
endmodule
