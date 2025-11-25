`timescale 1ns / 1ps
module imgMemReader # (
  parameter H_SIZE = 640,
  parameter V_SIZE = 480
)(
    input logic DE,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic [23:0] imgData, // RGB 888

    output logic [$clog2(H_SIZE*V_SIZE)-1:0] addr,
    output logic [7:0] r_port,
    output logic [7:0] g_port,
    output logic [7:0] b_port
);

  assign addr = (DE && (x < H_SIZE && y < V_SIZE)) ? y * H_SIZE + x : 'bz;
  assign {r_port, g_port, b_port} = (DE && (x < H_SIZE && y < V_SIZE)) ? imgData : 24'b0;

endmodule

