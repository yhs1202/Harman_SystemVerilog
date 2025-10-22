`timescale 1ns/1ps
module tb_APB_Interface_top ();
    logic PCLK;
    logic PRESET;

    APB_Interface_top dut (
        .PCLK(PCLK),
        .PRESET(PRESET)
    );

    always #10 PCLK = ~PCLK;

    initial begin
        PCLK = 1'b0;
        PRESET = 1'b1;
        #25;
        PRESET = 1'b0;

        #10000;
        $finish;
    end
    
endmodule