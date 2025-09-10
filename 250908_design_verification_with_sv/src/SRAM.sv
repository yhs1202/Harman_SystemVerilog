`timescale 1ns / 1ps
module SRAM(
    input clk,
    input rst,
    input logic [3:0] addr,
    input logic w_en,
    input logic [7:0] d,    // write data
    output logic [7:0] q    // read data
    );

    logic [7:0] mem[0:15];

    assign q = mem[addr];

    always_ff @(posedge clk or posedge rst) begin
        if (w_en) begin
            mem[addr] <= d;
        end
    end
endmodule


// `timescale 1ns / 1ps
// module register_8bit(
//     input clk,
//     input rst,
//     input logic [3:0] addr,
//     input logic wr,
//     input logic [7:0] w_data,    // write data
//     output logic [7:0] r_data    // read data
//     );
// 
//     logic [7:0] mem[0:15];
// 
//     assign r_data = mem[addr];
// 
//     always_ff @(posedge clk or posedge rst) begin
//         if (wr) begin
//             mem[addr] <= w_data;
//         end
//     end
// endmodule