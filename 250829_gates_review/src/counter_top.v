`timescale 1ns / 1ps
module counter_top(
    input clk, rst,
    output [7:0] fnd_data
    );

    wire [3:0] w_count;

    counter U_COUNTER (
        .clk (clk),
        .rst (rst),
        .count_reg (w_count)
    );

    bcd_decoder U_BCD_DECODER (
        .bcd_data (w_count),
        .fnd_data (fnd_data)
    );
endmodule
