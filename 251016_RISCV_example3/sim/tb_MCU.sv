`timescale 1ns/1ps
module tb_MCU();
    logic clk;
    logic rst;

    MCU U_MCU (
        .clk(clk),
        .reset(rst)
    );

    always #5 clk = ~clk;
    initial begin
        #0; clk = 1'b0; rst = 1'b1;
        #10; rst = 1'b0;
        #200; $stop;
    end
endmodule