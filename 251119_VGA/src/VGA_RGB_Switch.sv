`timescale 1ns/1ps

module VGA_RGB_Switch (
    input  logic [3:0] r_sw,
    input  logic [3:0] g_sw,
    input  logic [3:0] b_sw,
    input  logic       DE,    // Display Enable signal
    output logic [3:0] r_port, 
    output logic [3:0] g_port, 
    output logic [3:0] b_port
);
    
    assign r_port = DE ? r_sw : 4'b0;
    assign g_port = DE ? g_sw : 4'b0;
    assign b_port = DE ? b_sw : 4'b0;

endmodule
