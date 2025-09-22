`timescale 1ns/1ps
module register_nbit #(
    parameter WIDTH = 32
) (
    input logic clk,
    input logic rst,
    input logic w_en,
    input logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            q <= {WIDTH{1'b0}};
        end else if (w_en) begin
            q <= d;
        end
    end
endmodule