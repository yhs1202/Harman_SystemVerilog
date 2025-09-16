`timescale 1ns / 1ps
module SRAM(
    input clk,
    input rst,
    input logic w_en,
    input logic [3:0] addr, // added address from register_8bit
    input logic [7:0] d,    // write data
    output logic [7:0] q    // read data
    );

    logic [7:0] mem[0:15];  // 16 x 8-bit memory

    assign q = mem[addr];

    always_ff @(posedge clk or posedge rst) begin
        if (w_en) begin
            mem[addr] <= d;
        end
    end
endmodule