`timescale 1ns/1ps
module tb_spi_master_top ();
    parameter MS = 1000000;
    // global signals
    logic clk;
    logic rst;

    logic btn_runstop;
    logic btn_clear;

    // SPI signals
    logic SCLK;
    logic MOSI;
    logic MISO;
    logic SS_n;


    // Instantiate SPI Master Top
    spi_master_top u_spi_master_top (.*);


    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 1'b0; rst = 1'b1;
        #10;
        rst = 1'b0;
        #100;
        btn_runstop = 1'b1; // run


        #(MS * 20);

        btn_runstop = 1'b0; // stop
        #20;

        btn_clear = 1'b1; // clear
    end
endmodule