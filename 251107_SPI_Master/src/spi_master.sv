`timescale 1ns/1ps  

// SPI Master Module
// Description: This module implements an SPI Master with CPOL=0 and CPHA=0.
module spi_master (
    // global signals
    input logic clk,
    input logic rst,

    // internal signals
    input logic start,
    input logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic tx_ready,
    output logic done,       // Indicates completion of SPI transaction (tx, rx both)

    // SPI signals
    output logic SCLK,
    output logic MOSI,
    input logic MISO
);
    // State encoding
    typedef enum logic [1:0] {
        IDLE,
        CP0,
        CP1
    } state_t;

    
    state_t state_reg, state_next;
    logic [7:0] tx_data_reg, tx_data_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic [5:0] sclk_counter_reg, sclk_counter_next;   // SCLK period counter (0 to 49 for 50 cycles)
    logic [2:0] bit_counter_reg, bit_counter_next;       // Bit counter (0 to 7 for 8 bits)

    assign MOSI = tx_data_reg[7]; // MSB first
    assign rx_data = rx_data_reg;

    always_ff @( posedge clk, posedge rst ) begin : state_ff
        if (rst) begin
            state_reg <= IDLE;
            tx_data_reg <= 8'd0;
            rx_data_reg <= 8'd0;
            sclk_counter_reg <= 6'd0;
            bit_counter_reg <= 3'd0;
        end else begin
            state_reg <= state_next;
            tx_data_reg <= tx_data_next;
            rx_data_reg <= rx_data_next;
            sclk_counter_reg <= sclk_counter_next;
            bit_counter_reg <= bit_counter_next;
        end
    end


    always_comb begin : state_next_logic
        // Default assignments
        state_next = state_reg;
        tx_data_next = tx_data_reg;
        rx_data_next = rx_data_reg;
        sclk_counter_next = sclk_counter_reg;
        bit_counter_next = bit_counter_reg;
        tx_ready = 1'b0;
        done = 1'b0;
        SCLK = 1'b0;

        case (state_reg)
            IDLE: begin
                done = 1'b0;
                tx_ready = 1'b1;
                sclk_counter_next = 0;
                bit_counter_next = 0;
                // tx_data_next = 8'bz;
                if (start) begin
                    state_next = CP0;
                    tx_data_next = tx_data;
                end
            end

            CP0: begin
                SCLK = 1'b0;
                if (sclk_counter_reg == 49) begin
                    state_next = CP1;
                    sclk_counter_next = 0;
                    rx_data_next = {rx_data_reg[6:0], MISO};    // sample MISO on rising edge
                end else sclk_counter_next = sclk_counter_reg + 1;
            end

            CP1: begin
                SCLK = 1'b1;
                if (sclk_counter_reg == 49) begin
                    sclk_counter_next = 0;
                    if (bit_counter_reg == 7) begin
                        state_next = IDLE;
                        done = 1'b1;
                        bit_counter_next = 0;
                    end else begin
                        state_next = CP0;
                        tx_data_next = {tx_data_reg[6:0], 1'b0}; // Shift left
                        bit_counter_next = bit_counter_reg + 1;
                    end
                end else sclk_counter_next = sclk_counter_reg + 1;
            end

            default: begin
                state_next = IDLE;
            end
        endcase
        
    end

endmodule

