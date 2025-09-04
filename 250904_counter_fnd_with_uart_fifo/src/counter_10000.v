`timescale 1ns / 1ps
module counter_10000(
    input clk, rst, 
    input i_tick,
    input mode, // 0: up, 1: down
    input clear,
    output reg [$clog2(10000)-1:0] count_reg
    );

    always @(posedge clk, posedge rst) begin
        if (rst | clear) begin
            count_reg <= 0;
        end
        else begin
            if (i_tick) begin
                if (mode == 1) begin // up
                    if (count_reg == 0) begin
                        count_reg <= 9999;
                    end else begin
                        count_reg <= count_reg - 1;
                    end
                end 
                else begin // down
                    if (count_reg == 9999) begin
                        count_reg <= 0;
                    end else begin
                        count_reg <= count_reg + 1;
                    end
                end
            end
            else begin
                count_reg <= count_reg;
            end
        end
    end
endmodule
