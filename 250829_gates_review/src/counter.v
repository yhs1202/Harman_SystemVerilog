`timescale 1ns / 1ps
module counter (
    input clk, rst,
    output reg [3:0] count_reg
);
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count_reg <= 0;
        end else if (count_reg == 4'b1001) begin
            count_reg <= 0;
        end else begin
            count_reg <= count_reg + 1;
        end
    end
endmodule
