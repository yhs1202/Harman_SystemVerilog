`timescale 1ns / 1ps
module counter_top(
    input clk, rst,
    input mode,     // Btn_R, 0: up, 1: down
    input enable,   // Btn_L, 0: stop, 1: run
    input clear,    // Btn_U
    output [3:0] fnd_com,
    output [7:0] fnd_data
    );

    wire w_btn_enable, w_btn_clear, w_btn_mode;
    wire w_enable, w_clear, w_mode;
    wire [$clog2(10000)-1:0] w_count;


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
