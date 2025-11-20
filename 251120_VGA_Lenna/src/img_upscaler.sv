`timescale 1ns / 1ps
module img_upscaler (
    input logic DE,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic [15:0] imgData,

    output logic [$clog2(320*240)-1:0] addr,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port
);

  localparam H_SIZE = 320;
  localparam V_SIZE = 240;


  // Upscale 320x240 image to 640x480
  assign addr = DE ? (y >> 1) * H_SIZE + (x >> 1) : 'bz;
  assign {r_port, g_port, b_port} = DE ? {imgData[15:12], imgData[10:7], imgData[4:1]} : 12'b0;

endmodule

