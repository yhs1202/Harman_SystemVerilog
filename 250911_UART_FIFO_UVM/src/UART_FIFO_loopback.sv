`timescale 1ns / 1ps
module UART_FIFO_loopback(
    input logic clk,
    input logic rst,
    input logic rx,
    output logic tx,
    output logic baud_tick
    );

    // Internal signals
    logic [7:0] rx_data;
    logic rx_done;
    logic [7:0] fifo_data;
    logic rx_fifo_empty, rx_fifo_full;
    logic [7:0] tx_fifo_data;
    logic tx_fifo_empty, tx_fifo_full;
    logic tx_busy;

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
        .r_en(!tx_fifo_full),
        // .r_en(1'b1),  // always read
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
