`timescale 1ns/1ps
module register_file_32bit (
    input logic clk,
    input logic [4:0] r_addr_0,
    input logic [4:0] r_addr_1,
    input logic w_en,
    input logic [4:0] w_addr,
    input logic [31:0] w_data,

    output logic [31:0] r_data_0,
    output logic [31:0] r_data_1
);

    logic [31:0] mem [0:31];

    assign r_data_0 = mem[r_addr_0];
    assign r_data_1 = mem[r_addr_1];

    always_ff @( posedge clk ) begin : blockName
        if (w_en) begin
            mem[w_addr] <= w_data;
        end
    end

    initial begin
        mem[0] = 32'd0;  // $0
        mem[1] = 32'd1;  // $1
        mem[2] = 32'd2;  // $2
        mem[3] = 32'd3;  // $3
        mem[4] = 32'd4;  // $4
        mem[5] = 32'd5;  // $5
        mem[6] = 32'd6;  // $6
        mem[7] = 32'd7;  // $7
        mem[8] = 32'd8;  // $8
        mem[9] = 32'd9;  // $9
    end
endmodule