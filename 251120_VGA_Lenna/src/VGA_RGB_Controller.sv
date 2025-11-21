`timescale 1ns / 1ps
module VGA_RGB_Controller (
    input logic clk,
    input logic reset,
    // input logic [3:0] r_sw,
    // input logic [3:0] g_sw,
    // input logic [3:0] b_sw,
    input logic mode_sel,   // 0: lenna, 1: test pattern
    input logic scale_sel,  // 0: 640x480, 1: 320x240
    input logic gray_sel,   // 0: color, 1: grayscale

    output logic h_sync,
    output logic v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port

);
  logic DE;
  logic [9:0] pixel_x;
  logic [9:0] pixel_y;
  logic [11:0] rgb_normal;
  logic [11:0] rgb_0;
  logic [11:0] rgb_1;
  logic [11:0] rgb_2;

  logic [$clog2(320*240)-1:0] addr;
  logic [$clog2(320*240)-1:0] addr_vga;
  logic [$clog2(320*240)-1:0] addr_qvga;
  logic [15:0] imgData;
  logic [15:0] imgData_vga;
  logic [15:0] imgData_qvga;
  logic p_clk;


  logic [11:0] rgb_gray;

  assign rgb_normal = ({mode_sel, scale_sel}==2'b00) ? rgb_0 :
                    ({mode_sel, scale_sel}==2'b01) ? rgb_1 : rgb_2;

  assign {r_port, g_port, b_port} = (gray_sel) ? rgb_gray : rgb_normal;

  assign addr = ({mode_sel, scale_sel}==2'b00) ? addr_qvga :
                ({mode_sel, scale_sel}==2'b01) ? addr_vga : 0;

  assign imgData_qvga = ({mode_sel, scale_sel} == 2'b00) ? imgData : 0;
  assign imgData_vga = ({mode_sel, scale_sel} == 2'b01) ? imgData : 0;

  pixel_clk_gen pixel_clk_inst (
      .clk  (clk),
      .reset(reset),
      .p_clk(p_clk)
  );

  VGA_Syncher U_VGA_Syncher (
      .clk(p_clk),
      .reset(reset),
      .h_sync(h_sync),
      .v_sync(v_sync),
      .DE(DE),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y)
  );

  // VGA_RGB_Switch vga_rgb_switch_inst (
  //     .r_sw(r_sw),
  //     .g_sw(g_sw),
  //     .b_sw(b_sw),
  //     .DE(DE),
  //     .r_port(rgb_0[11:8]),
  //     .g_port(rgb_0[7:4]),
  //     .b_port(rgb_0[3:0])
  // );

  test_pattern_gen test_pattern_gen_inst (
      .clk(clk),
      .reset(reset),
      .x(pixel_x),
      .y(pixel_y),
      .DE(DE),
      .rgb(rgb_2)
  );

  imgROM img_rom_inst (
      .clk(p_clk),
      .addr(addr),
      .data(imgData)
  );

  imgMemReader img_mem_reader_inst (
      .DE(DE),
      .x(pixel_x),
      .y(pixel_y),
      .imgData(imgData_vga),
      .addr(addr_vga),
      .r_port(rgb_1[11:8]),
      .g_port(rgb_1[7:4]),
      .b_port(rgb_1[3:0])
  );

  img_upscaler img_mem_reader_upscale_inst (
      .DE(DE),
      .x(pixel_x),
      .y(pixel_y),
      .imgData(imgData_qvga),
      .addr(addr_qvga),
      .r_port(rgb_0[11:8]),
      .g_port(rgb_0[7:4]),
      .b_port(rgb_0[3:0])
  );

  img_grayscaler img_grayscaler_inst (
      .DE(DE),
      .rgb_in(rgb_normal),
      .rgb_out(rgb_gray)
  );
endmodule
