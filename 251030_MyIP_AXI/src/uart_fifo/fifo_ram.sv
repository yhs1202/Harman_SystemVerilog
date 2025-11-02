`timescale 1ns / 1ps
module fifo_ram #(
    parameter DEPTH = 8,
    localparam ADDR_WIDTH = $clog2(DEPTH)
)(
    input logic clk,
    input logic w_en,
    input logic [ADDR_WIDTH-1:0] w_addr,
    input logic [7:0] w_data,
    input logic [ADDR_WIDTH-1:0] r_addr,
    output logic [7:0] r_data
    );
    

    logic [7:0] mem[0:DEPTH-1];
    assign r_data = mem[r_addr];

    always_ff @(posedge clk) begin
        if (w_en) begin
            mem[w_addr] <= w_data;
        end
    end
endmodule
