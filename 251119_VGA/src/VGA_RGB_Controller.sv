`timescale 1ns / 1ps
module VGA_RGB_Controller (
    input logic clk,
    input logic reset,
    input logic [3:0] r_sw,
    input logic [3:0] g_sw,
    input logic [3:0] b_sw,
    input logic sel,  // sw/color-bar mode

    output logic h_sync,
    output logic v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port

);
  logic [9:0] pixel_x;
  logic [9:0] pixel_y;
  logic DE;
  logic [11:0] rgb_port;
  logic [11:0] rgb_0;
  logic [11:0] rgb_1;

  assign rgb_port = (sel) ? rgb_0 : rgb_1;
  assign {r_port, g_port, b_port} = rgb_port;

  VGA_Decoder_top vga_decoder_top_inst (
      .clk(clk),
      .reset(reset),
      .h_sync(h_sync),
      .v_sync(v_sync),
      .DE(DE),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y)
  );


  VGA_RGB_Switch vga_rgb_switch_inst (
      .r_sw(r_sw),
      .g_sw(g_sw),
      .b_sw(b_sw),
      .DE(DE),
      .r_port(rgb_0[11:8]),
      .g_port(rgb_0[7:4]),
      .b_port(rgb_0[3:0])
  );

  test_pattern_gen test_pattern_gen_inst (
      .clk(clk),
      .reset(reset),
      .x(pixel_x),
      .y(pixel_y),
      .DE(DE),
      .rgb(rgb_1)
  );

endmodule
