`timescale 1ns / 1ps
module adder_8bit(
    input logic [7:0] a,
    input logic [7:0] b,
    input logic mode,
    output logic [7:0] sum,
    output logic carry_out
    );

    always_comb begin : mode_select
        if (mode == 1'b0) begin
            {carry_out, sum} = a + b; // Addition
        end else begin
            {carry_out, sum} = a - b; // Subtraction
        end
    end

endmodule
