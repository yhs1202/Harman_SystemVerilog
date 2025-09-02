`timescale 1ns / 1ps
module tb_counter_top();
    reg clk, rst;
    wire [7:0] fnd_data;

    counter_top uut (
        .clk (clk),
        .rst (rst),
        .fnd_data (fnd_data)
    );

    always #10 clk = ~clk;

    initial begin
        #0 clk=0; rst=1;
        #10 rst=0;
        #1000
        $finish;
    end

endmodule
