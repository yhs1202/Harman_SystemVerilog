`timescale 1ns/1ps
// SPI Slave Module
module spi_slave (
    // global signals
    input logic clk,
    input logic rst,

    // SPI signals
    input logic SCLK,
    input logic MOSI,
    output logic MISO,
    input logic SS_n, // Slave Select (active low)

    // internal signals
    // input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic rx_done
);

    // Edge detection for SCLK
    logic SCLK_reg, SCLK_rising, SCLK_falling;
    always_ff @( posedge clk, posedge rst ) begin : sclk_edge_ff
        if (rst) begin
            SCLK_reg <= 1'b0;
            SCLK_rising <= 1'b0;
            // SCLK_falling <= 1'b0;
        end else begin
            SCLK_reg <= SCLK;
            SCLK_rising <= (SCLK_reg == 1'b0 && SCLK == 1'b1);
            // SCLK_falling <= (SCLK_reg == 1'b1 && SCLK == 1'b0);
        end
    end


    // Shift registers and counters
    logic [7:0] rx_shift_reg;
    // logic [7:0] tx_shift_reg;
    logic [2:0] bit_counter;


    // assign MISO = SS_n ? 1'bz : tx_shift_reg[7]; // MSB first
    assign rx_data = rx_shift_reg;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            rx_shift_reg <= 8'b0;
            bit_counter <= 3'b0;
            rx_done <= 1'b0;
        end else begin
            // Clear rx_done after one clock cycle
            rx_done <= 1'b0;
            if (SS_n) begin
                // reset counters
                bit_counter <= 3'b0;
                rx_shift_reg <= 8'b0; // preload with previous data
                
            end else begin
                // On SCLK rising edge, sample MOSI
                if (SCLK_rising) begin
                    rx_shift_reg <= {rx_shift_reg[6:0], MOSI};
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == 7) rx_done <= 1'b1;
                end
            end
        end
    end
endmodule