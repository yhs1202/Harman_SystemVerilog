`timescale 1ns / 1ps

module UART_FIFO_CORE (
    input  logic clk,
    input  logic rst,

    // Status Signals
    output logic rx_full, tx_empty, tx_full, rx_empty,

    // RX Interface
    input logic rx,
    output logic [7:0] rx_data,
    input logic rx_re,

    // TX Interface
    output logic tx,
    input logic [7:0] tx_data,
    input logic tx_we
);

    logic baud_tick;
    logic [7:0] rx_fifo_data;
    logic [7:0] tx_fifo_data;
    logic rx_done, tx_busy;


    // Baud Rate Generator
    baud_tick_gen #(
        .BAUD_RATE(9600),
        .OVERSAMPLING(16)
    ) U_BAUD_TICK_GEN (
        .clk(clk),
        .rst(rst),
        .b_tick(baud_tick)
    );

    fifo_top U_RX_FIFO (
        .clk(clk),
        .rst(rst),
        .w_en(rx_done),
        .r_en(rx_re),
        .w_data(rx_fifo_data),
        .r_data(rx_data),
        .full(rx_full),
        .empty(rx_empty)
    );

    UART_Rx_new U_UART_RX (
        .clk(clk),
        .rst(rst),
        .b_tick(baud_tick),
        .rx(rx),
        .rx_data(rx_fifo_data), // rx_fifo in
        .rx_done(rx_done)
    );

    fifo_top U_TX_FIFO (
        .clk(clk),
        .rst(rst),
        .w_en(tx_we),
        .r_en(~tx_busy),
        .w_data(tx_data),
        .r_data(tx_fifo_data), // tx_fifo out
        .full(tx_full),
        .empty(tx_empty)
    );

    UART_TX U_UART_TX (
        .clk(clk),
        .rst(rst),
        .b_tick(baud_tick),
        .tx_start(~tx_empty),
        .tx_data(tx_fifo_data),
        .tx_busy(tx_busy),
        .tx(tx)
    );

endmodule
