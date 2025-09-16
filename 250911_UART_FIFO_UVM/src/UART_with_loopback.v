`timescale 1ns / 1ps
module UART_with_loopback(
    input clk,
    input rst,
    input rx,
    output tx
    );

    // rx_done <-> tx_start
    // rx_data <-> tx_data
    wire w_rx_done;
    wire [7:0] w_rx_data;

    UART_top U_UART_TOP (
        .clk(clk),
        .rst(rst),
        .tx_start(w_rx_done),
        .tx_data(w_rx_data),
        .rx(rx),

        .tx_busy(),
        .tx(tx),
        .rx_data(w_rx_data),
        // .rx_busy(),
        .rx_done(w_rx_done)
    );
endmodule
