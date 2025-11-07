`timescale 1ns/1ps
module spi_top (
    // global signals
    input logic clk,
    input logic rst,

    // User imputs
    input logic btn_runstop,
    input logic btn_clear,


    // internal signals
    input logic start,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic tx_ready,
    output logic done,  // tx done in this time.
    output logic rx_done,


    // output fnd signals
    output logic [3:0] fnd_com,
    output logic [6:0] fnd_data
);
    
    // SPI signals
    logic SCLK;
    logic MOSI;
    logic MISO; // not used
    logic SS_n; // Slave Select (active low)

    // instantiate SPI
    spi_master_top U_SPI_MASTER_TOP (.*);
    spi_slave_top U_SPI_SLAVE_TOP (.*);
endmodule