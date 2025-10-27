`timescale 1ns / 1ps

module tb_MCU ();

    logic       clk;
    logic       reset;
    logic [7:0] gpo;
    logic [7:0] gpi;
    wire [7:0] gpio;
    logic       RX;
    logic       TX;

    MCU dut (.*);

    always #5 clk = ~clk;

    initial begin
        #00 clk = 0;
        reset = 1;
        #10 reset = 0;

        #100_000;
        $finish;
    end
endmodule
