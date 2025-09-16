`timescale 1ns / 1ps
module register_8bit(
    input clk,
    input rst,
    input logic w_en,
    input logic [7:0] d,    // write data
    output logic [7:0] q    // read data
    );

    logic [7:0] q_buff;

    assign q = q_buff;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            q_buff <= 0;
        end else if (w_en) begin
            q_buff <= d;
        // end else begin
            // q <= q_buff;
        end
    end
endmodule