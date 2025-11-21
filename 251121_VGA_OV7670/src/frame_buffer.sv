// Description: Frame buffer module for storing pixel data from OV7670 camera
//              and providing it to VGA controller for display. (CDC compliant)
`timescale 1ns/1ps

module frame_buffer (
    // Write interface
    input logic wclk,
    input logic we,
    input logic [16:0] wAddr,
    input logic [15:0] wData,

    // Read interface
    input logic rclk,
    input logic oe,
    input logic [16:0] rAddr,
    output logic [15:0] rData
);
    // Declare the memory array
    logic [15:0] mem[0:(320*240)-1];

    // Write operation (from OV7670)
    always_ff @(posedge wclk) begin
        if (we) mem[wAddr] <= wData;
    end

    // Read operation (to VGA controller)
    always_ff @(posedge rclk) begin
        if (oe) rData <= mem[rAddr];
        else rData <= 16'b0; // Output zero when not enabled
    end

endmodule