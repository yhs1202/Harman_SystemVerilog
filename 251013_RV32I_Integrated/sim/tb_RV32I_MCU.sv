`timescale 1ns/1ps
module tb_RV32I_MCU();
    logic clk;
    logic rst;

    RV32I_MCU U_RV32I_MCU (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;
    initial begin
        #0; clk = 1'b0; rst = 1'b1;
        #10; rst = 1'b0;
        #200; $stop;
    end
endmodule