`timescale 1ns/1ps

module OV7670_Mem_Controller (
    input logic pclk,
    input logic reset,
    // OV7670 Camera Interface
    input logic href,   // Horizontal reference signal
    input logic vsync,  // Vertical sync signal
    input logic [7:0] data, // 8-bit pixel data from OV7670

    // Memory Interface
    output logic mem_we,          // Memory write enable
    output logic [16:0] mem_addr, // Memory address (320 x 240)
    output logic [15:0] mem_wdata   // Memory data input (2 bytes per pixel)
);

    logic [16:0] pixelCounter; // 640 x 240
    logic [15:0] pixelData;

    assign mem_wdata = pixelData;

    always_ff @(posedge pclk) begin
        if (reset) begin
            pixelCounter <= 0;
            pixelData <= 0;
            mem_we <= 1'b0;
            mem_addr <= 0;
        end else begin
            if (href) begin
                if (!pixelCounter[0]) begin
                    mem_we <= 1'b0; // Wait for second byte
                    // First byte of pixel data (high byte)
                    pixelData[15:8] <= data;
                end else begin
                    // Second byte of pixel data (low byte)
                    mem_we <= 1'b1; // Enable write after second byte
                    pixelData[7:0] <= data;
                    mem_addr <= mem_addr + 1;
                end
                pixelCounter <= pixelCounter + 1;
            end
            else if (vsync) begin
                mem_we <= 1'b0; // Disable write on vsync
                pixelCounter <= 0; // Reset address counter on vsync
                mem_addr <= 0;
            end
        end
    end
endmodule
