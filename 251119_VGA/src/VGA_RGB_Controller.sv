`timescale 1ns/1ps
module VGA_RGB_Controller (
    input  logic clk,
    input  logic reset,
    input  logic [3:0] r_sw,
    input  logic [3:0] g_sw,
    input  logic [3:0] b_sw,
    output logic h_sync,
    output logic v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port
);
    logic DE;


    VGA_Decoder_top vga_decoder_top_inst (
        .clk(clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .pixel_x(),
        .pixel_y()
    );

    VGA_RGB_Switch vga_rgb_switch_inst (
        .r_sw(r_sw),
        .g_sw(g_sw),
        .b_sw(b_sw),
        .DE(DE),
        .r_port(r_port),
        .g_port(g_port),
        .b_port(b_port)
    );
    
endmodule