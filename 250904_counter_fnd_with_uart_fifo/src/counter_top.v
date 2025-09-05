`timescale 1ns / 1ps
module counter_top(
    input clk, rst,
    input mode,     // Btn_R, 0: up, 1: down
    input enable,   // Btn_U, 0: stop, 1: run
    input clear,    // Btn_L

    input rx,
    output tx,
    
    output [3:0] fnd_com,
    output [7:0] fnd_data
    );

    wire w_btn_enable, w_btn_clear, w_btn_mode;
    wire w_enable, w_clear, w_mode;
    // wire w_uart_enable, w_uart_clear, w_uart_mode;
    wire [$clog2(10000)-1:0] w_count;

    wire [7:0] w_rx_data;
    wire w_rx_done;

    // command_controller_unit U_COMMAND_CONTROLLER_UNIT (
    //     .clk (clk),
    //     .rst (rst),
    //     .rx_data (w_rx_data),
    //     .rx_done (w_rx_done),

    //     .enable_cmd (w_uart_enable),
    //     .clear_cmd (w_uart_clear),
    //     .mode_cmd (w_uart_mode)
    // );

    UART_top U_UART_TOP (
        .clk(clk),
        .rst(rst),
        .tx_start(w_rx_done),
        .tx_data(w_rx_data),
        .rx(rx),

        .tx_busy(),
        .tx(tx),
        .rx_data(w_rx_data),
        .rx_busy(),
        .rx_done(w_rx_done)
    );


    btn_debounce U_BTN_DEBOUNCE_ENABLE (
        .clk (clk),
        .rst (rst),
        .btn_in (enable),
        .btn_out (w_btn_enable)
    );

    btn_debounce U_BTN_DEBOUNCE_CLEAR (
        .clk (clk),
        .rst (rst),
        .btn_in (clear),
        .btn_out (w_btn_clear)
    );

    btn_debounce U_BTN_DEBOUNCE_MODE (
        .clk (clk),
        .rst (rst),
        .btn_in (mode),
        .btn_out (w_btn_mode)
    );

    counter_controller_unit U_COUNTER_CONTROLLER_UNIT (
        .clk (clk),
        .rst (rst),
        .btn_enable (w_btn_enable),
        .btn_clear (w_btn_clear),
        .btn_mode (w_btn_mode),
        .rx_data (w_rx_data),
        .rx_done (w_rx_done),

        .enable (w_enable),
        .clear (w_clear),
        .mode (w_mode)
    );

    datapath_counter_10000 U_DATAPATH_COUNTER_10000 (
        .clk (clk),
        .rst (rst),
        .mode (w_mode),
        .enable (w_enable),
        .clear (w_clear),
        
        .count_reg (w_count)
    );

    fnd_controller U_FND_CONTROLLER (
        .clk (clk),
        .rst (rst),
        .count_reg (w_count),

        .fnd_com (fnd_com),
        .fnd_data (fnd_data)
    );

endmodule
