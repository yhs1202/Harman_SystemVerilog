`timescale 1ns / 1ps
module img_upscaler (
    input logic DE,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic [15:0] imgData,
    // input logic [2:0] sw_rgb,

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

  /*
  // Seperate R, G, B channels with switches
  always_comb begin
    if (!DE) {r_port, g_port, b_port} = 12'b0;
    else begin
      if (sw_rgb[2] == 1'b0) r_port = 4'b0;
      else r_port = imgData[15:12];

      if (sw_rgb[1] == 1'b0) g_port = 4'b0;
      else g_port = imgData[10:7];

      if (sw_rgb[0] == 1'b0) b_port = 4'b0;
      else b_port = imgData[4:1];
    end
  end
    */
endmodule

