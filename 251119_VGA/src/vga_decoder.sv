`timescale 1ns/1ps
module vga_decoder (
    input logic [9:0] h_counter,
    input logic [9:0] v_counter,
    output logic h_sync,
    output logic v_sync
    // Additional VGA signals can be added here
);

    localparam H_visible_area = 640;
    localparam H_front_porch  = 16;
    localparam H_sync_pulse   = 96;
    localparam H_back_porch   = 48;

    localparam V_visible_area = 480;
    localparam V_front_porch  = 10;
    localparam V_sync_pulse   = 2;
    localparam V_back_porch   = 33;

    // assign h_sync = (h_counter >= 656 && h_counter < 752) ? 0 : 1; // Horizontal sync pulse
    assign h_sync = (h_counter >= H_visible_area + H_front_porch && 
                     h_counter < H_visible_area + H_front_porch + H_sync_pulse) ? 0 : 1; // Horizontal sync pulse

    // assign v_sync = (v_counter >= 490 && v_counter < 492) ? 0 : 1; // Vertical sync pulse
    assign v_sync = (v_counter >= V_visible_area + V_front_porch && 
                     v_counter < V_visible_area + V_front_porch + V_sync_pulse) ? 0 : 1; // Vertical sync pulse


endmodule