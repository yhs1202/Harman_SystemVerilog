`timescale 1ns / 1ps
module UART_top(
    input clk, rst,
    input tx_start,
    input [7:0] tx_data,
    output tx_busy,
    output tx
);
    wire w_b_tick;

    baud_tick_gen U_BAUD_TICK_GEN(
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)
    );

    UART_Tx U_UART_TX(
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .b_tick(w_b_tick),
        .tx_data(tx_data),
        
        .tx_busy(tx_busy),
        .tx(tx)
    );
endmodule
