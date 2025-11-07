`timescale 1ns/1ps
module spi_top (
    // global signals
    input logic clk,
    input logic rst,

    // User imputs
    input logic btn_runstop,
    input logic btn_clear,


    // output fnd signals
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,

    // SPI signals
    output logic master_SCLK,
    output logic master_MOSI,
    input logic master_MISO, // not used
    output logic master_SS_n, // Slave Select (active low)

    
    input logic slave_SCLK,
    input logic slave_MOSI,
    output logic slave_MISO, // not used
    input logic slave_SS_n // Slave Select (active low)
);

    // instantiate SPI
    spi_master_top U_SPI_MASTER_TOP (
        .*,
        .SCLK (master_SCLK),
        .MOSI (master_MOSI),
        .MISO (master_MISO),
        .SS_n (master_SS_n)
    );

    spi_slave_top U_SPI_slave_TOP (
        .*,
        .SCLK (slave_SCLK),
        .MOSI (slave_MOSI),
        .MISO (slave_MISO),
        .SS_n (slave_SS_n)
    );
endmodule