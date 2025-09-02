`timescale 1ns / 1ps
module tick_gen #(
    parameter TICK_CYCLE = 100_000_000 / 10 // 10Hz
)(
    input clk, rst,
    input enable, clear,
    output reg o_tick
    );

    localparam WIDTH = $clog2(TICK_CYCLE);
    reg [WIDTH-1:0] r_count;
    always @(posedge clk, posedge rst) begin
        if (rst | clear) begin
            r_count <= 0;
            o_tick <= 0;
        end 
        else begin
            if (enable) begin
                // counter
                if (r_count == TICK_CYCLE - 1) begin
                    r_count <= 0;
                    o_tick <= 1;
                end else begin
                    r_count <= r_count + 1;
                    o_tick <= 0;
                end
            end
            else begin
                r_count <= r_count;
                o_tick <= 0;
            end
        end
    end
endmodule
