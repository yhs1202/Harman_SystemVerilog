`timescale 1ns/1ps
module tb_sum_1to10 ();
    logic clk;
    logic rst;
    logic [7:0] out = 0;

    sum_1to10 dut (
        .clk (clk),
        .rst (rst),
        .out (out)
    );

    always #5 clk = ~clk;

    initial begin
        #0; clk = 0; rst = 0;
        #10; rst = 1;
        #10; rst = 0;
        #1000;
        $stop;


        
    end
    endmodule