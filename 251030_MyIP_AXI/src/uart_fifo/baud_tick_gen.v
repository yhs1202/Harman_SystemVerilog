`timescale 1ns / 1ps
module baud_tick_gen #(
    // 9600 baud rate, 16x oversampling
    parameter CLK_FREQ = 100_000_000,   // FPGA clock frequency (100 MHz)
    parameter BAUD_RATE = 9600,         // Desired baud rate
    parameter OVERSAMPLING = 16         // Oversampling factor
)(
    input clk, rst,
    output reg b_tick
);

    localparam BAUD_COUNT = CLK_FREQ / (BAUD_RATE * OVERSAMPLING) - 1;

    reg [$clog2(BAUD_COUNT)-1:0] baud_tick_counter;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            baud_tick_counter <= 0;
            b_tick <= 0;
        end
        else begin
            if (baud_tick_counter == BAUD_COUNT) begin
                baud_tick_counter <= 0;
                b_tick <= 1;
            end
            else begin
                baud_tick_counter <= baud_tick_counter + 1;
                b_tick <= 0;
            end
        end
    end
endmodule
