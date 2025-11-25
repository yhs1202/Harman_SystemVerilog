`timescale 1ns / 1ps
module VGA_Syncher (
    input logic clk,
    input logic reset,
    output logic h_sync,
    output logic v_sync,
    output logic DE,
    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y
);

  logic p_clk;
  logic [9:0] h_counter;
  logic [9:0] v_counter;

  // Instantiation
  //   pixel_clk_gen pixel_clk_inst (
  //       .clk  (clk),
  //       .reset(reset),
  //       .p_clk(p_clk)
  //   );

  pixel_counter pixel_counter_inst (
      .clk(clk),
      .reset(reset),
      .h_counter(h_counter),
      .v_counter(v_counter)
  );

  vga_decoder vga_decoder_inst (
      .h_counter(h_counter),
      .v_counter(v_counter),
      .h_sync(h_sync),
      .v_sync(v_sync),
      .DE(DE),
      .pixel_x(pixel_x),
      .pixel_y(pixel_y)
  );
endmodule

