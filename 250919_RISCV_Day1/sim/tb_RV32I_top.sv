`timescale 1ns/1ps
module tb_RV32I_top();
    logic clk;
    logic rst;

    RV32I_top U_RV32I_TOP (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;
    initial begin
        #0; clk = 1'b0; rst = 1'b1;
        #20; rst = 1'b0;
        #500; $stop;
    end
endmodule