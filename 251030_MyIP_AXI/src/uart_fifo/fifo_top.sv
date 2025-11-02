`timescale 1ns / 1ps
module fifo_top(
    input logic clk,
    input logic rst,
    input logic w_en,
    input logic r_en,
    input logic [7:0] w_data,
    output logic [7:0] r_data,
    output logic full,
    output logic empty
    );

    logic [2:0] w_addr;
    logic [2:0] r_addr;

    fifo_control_unit #(
        .DEPTH(8)
    ) U_FIFO_CONTROL_UNIT (
        .clk(clk),
        .rst(rst),
        .w_en(w_en),
        .r_en(r_en),
        .full(full),
        .empty(empty),
        .w_addr(w_addr),
        .r_addr(r_addr)
    );

    fifo_ram #(
        .DEPTH(8)
    ) U_FIFO_RAM (
        .clk(clk),
        .w_en(w_en),
        .w_addr(w_addr),
        .w_data(w_data),
        .r_addr(r_addr),
        .r_data(r_data)
    );

endmodule
