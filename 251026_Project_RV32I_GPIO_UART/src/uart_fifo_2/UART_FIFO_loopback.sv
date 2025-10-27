`timescale 1ns / 1ps
module UART_FIFO_loopback(
    input logic clk,
    input logic rst,

    input logic tx_w_en,
    output logic tx_fifo_empty,
    output logic tx_busy,
    output logic tx,

    output logic [7:0] fifo_data, // data read from RX FIFO
    input logic rx_r_en,
    output logic rx_done,
    input logic rx
    );
    logic baud_tick;

    logic rx_fifo_empty;
    assign tx_w_en = !rx_fifo_empty;

    logic tx_fifo_full;
    assign rx_r_en = !tx_fifo_full;

    // Internal signals
    logic [7:0] tx_fifo_data;
    logic [7:0] rx_data;    // RX FIFO input

    // Instantiate UART
    UART_top U_UART_TOP (
        .clk(clk),
        .rst(rst),
        .tx_start(!tx_fifo_empty),
        .tx_data(tx_fifo_data),
        .rx(rx),

        .tx_busy(tx_busy), // tx_fifo pop
        .tx(tx),
        .rx_data(rx_data),
        .rx_done(rx_done), // rx_fifo push
        .baud_tick(baud_tick)
    );

    // Instantiate RX FIFO
    fifo_top U_RX_FIFO_TOP (
        .clk(clk),
        .rst(rst),
        .w_en(rx_done),
        // .r_en(!tx_fifo_full),
        .r_en(1'b1),  // always read
        .w_data(rx_data),

        .r_data(fifo_data),
        .full(),
        .empty(rx_fifo_empty)
    );

    // Instantiate TX FIFO
    fifo_top U_TX_FIFO_TOP (
        .clk(clk),
        .rst(rst),
        .w_en(!rx_fifo_empty),
        .r_en(!tx_busy),
        .w_data(fifo_data),

        .r_data(tx_fifo_data),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty)
    );


endmodule
