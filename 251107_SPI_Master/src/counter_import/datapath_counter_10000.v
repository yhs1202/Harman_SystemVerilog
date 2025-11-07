`timescale 1ns/1ps
module datapath_counter_10000(
    input clk, rst, 
    input mode, 
    input enable, clear,
    output [$clog2(10000)-1:0] count_reg
    );

    wire [$clog2(10000)-1:0] w_count;
    wire w_clk_div;

    assign count_reg = w_count;

    // tick gen 10hz
    tick_gen #(
        // .TICK_CYCLE(100_000_000 / 10) // 10Hz
        .TICK_CYCLE(100_000 / 10) // for simulation
    ) U_TICK_GEN (
        .clk (clk),
        .rst (rst),
        .enable (enable),
        .clear (clear),

        .o_tick (w_clk_div)
    );

    counter_10000 U_COUNTER_10000 (
        .clk (clk),
        .rst (rst),
        .i_tick (w_clk_div),
        .mode (mode),
        .clear (clear),

        .count_reg (w_count)
    );
endmodule