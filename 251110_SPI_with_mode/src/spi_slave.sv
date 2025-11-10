`timescale 1ns/1ps
// SPI Slave Module
// Modified to support high impedance state on MISO when SS_n is inactive. (25.11.10)

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
    output logic [7:0] rx_data, // sampled MOSI data
    output logic rx_done,
    input logic [7:0] tx_data,  // data to transmit via MISO
    input logic tx_start,
    output logic tx_ready
    // output logic tx_done
);

    // 2-stage synchronizer for SCLK Edge detection
    logic sclk_sync_0, sclk_sync_1;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            sclk_sync_0 <= 1'b0;
            sclk_sync_1 <= 1'b0;
        end else begin
            sclk_sync_0 <= SCLK;
            sclk_sync_1 <= sclk_sync_0;
        end
    end

    // Edge detection
    wire SCLK_rising = (sclk_sync_1 == 1'b0 && sclk_sync_0 == 1'b1);
    wire SCLK_falling = (sclk_sync_1 == 1'b1 && sclk_sync_0 == 1'b0);

    /* removed for metastability issue
    logic SCLK_reg, SCLK_rising, SCLK_falling;
    always_ff @( posedge clk, posedge rst ) begin : sclk_edge_ff
        if (rst) begin
            SCLK_reg <= 1'b0;
            SCLK_rising <= 1'b0;
            SCLK_falling <= 1'b0;
        end else begin
            SCLK_reg <= SCLK;
            SCLK_rising <= (SCLK_reg == 1'b0 && SCLK == 1'b1);
            SCLK_falling <= (SCLK_reg == 1'b1 && SCLK == 1'b0);
        end
    end
    */


    /* 
    // Shift registers and counters
    logic [7:0] rx_shift_reg;
    // logic [7:0] tx_shift_reg;
    logic [2:0] bit_counter;


    // assign MISO = SS_n ? tx_shift_reg[7] : 1'bz; // MSB first
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
    */


    /* Slave in sequence implementation */
    typedef enum {
        SI_IDLE, 
        SI_PHASE
    } si_state_t;

    si_state_t si_state_reg, si_state_next; // slave in
    logic [2:0] rx_bit_counter_reg, rx_bit_counter_next;
    logic [7:0] rx_data_reg, rx_data_next;
    logic rx_done_reg, rx_done_next;

    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            si_state_reg <= SI_IDLE;
            rx_bit_counter_reg <= 3'b0;
            rx_data_reg <= 8'b0;
            rx_done_reg <= 1'b0;
        end else begin
            si_state_reg <= si_state_next;
            rx_bit_counter_reg <= rx_bit_counter_next;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    always_comb begin
        // Default assignments
        si_state_next = si_state_reg;
        rx_bit_counter_next = rx_bit_counter_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = rx_done_reg;

        case (si_state_reg)
            SI_IDLE: begin
                rx_done_next = 1'b0;
                if (!SS_n) begin
                    si_state_next = SI_PHASE;
                    rx_bit_counter_next = 0;
                end
            end
            SI_PHASE: begin
                if (!SS_n) begin
                    // posedge SCLK: sample MOSI
                    if (SCLK_rising) begin
                        rx_data_next = {rx_data[6:0], MOSI};
                        if (rx_bit_counter_reg == 7) begin
                            si_state_next = SI_IDLE;
                            rx_bit_counter_next = 0;
                            rx_done_next = 1'b1;
                        end else rx_bit_counter_next = rx_bit_counter_reg + 1;
                    end
                end else begin
                    si_state_next = SI_IDLE;
                end
            end
        endcase
    end

    /* Slave out sequence implementation */
    typedef enum {
        SO_IDLE, 
        SO_PHASE
    } so_state_t;

    so_state_t so_state_reg, so_state_next; // slave out
    logic [2:0] tx_bit_counter_reg, tx_bit_counter_next;
    logic [7:0] tx_data_reg, tx_data_next;
    // logic tx_done_reg, tx_done_next;

    // assign tx_done = tx_done_reg;
    assign MISO = SS_n ? 1'bz : tx_data_reg[7]; // MSB first

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            so_state_reg <= SO_IDLE;
            tx_bit_counter_reg <= 3'b0;
            tx_data_reg <= 8'b0;
            // tx_done_reg <= 1'b0;
        end else begin
            so_state_reg <= so_state_next;
            tx_bit_counter_reg <= tx_bit_counter_next;
            tx_data_reg <= tx_data_next;
            // tx_done_reg <= tx_done_next;
        end
    end

    always_comb begin
        // Default assignments
        so_state_next = so_state_reg;
        tx_bit_counter_next = tx_bit_counter_reg;
        tx_data_next = tx_data_reg;
        // tx_done_next = tx_done_reg;
        tx_ready = 1'b0;

        case (so_state_reg)
            SO_IDLE: begin
                // tx_done_next = 1'b0;
                if (!SS_n) begin
                    tx_ready = 1'b1;
                    if (tx_start) begin
                        so_state_next = SO_PHASE;
                        tx_data_next = tx_data;
                        tx_bit_counter_next = 0;
                    end
                end
            end
            SO_PHASE: begin
                if (!SS_n) begin
                    // negedge SCLK: shift out MISO
                    if (SCLK_falling) begin
                        tx_data_next = {tx_data_reg[6:0], 1'b0};
                        if (tx_bit_counter_reg == 7) begin
                            so_state_next = SO_IDLE;
                            tx_bit_counter_next = 0;
                            // tx_done_next = 1'b1;
                        end else tx_bit_counter_next = tx_bit_counter_reg + 1;
                    end
                end else begin
                    so_state_next = SO_IDLE;
                end
                
            end
        endcase
    end
endmodule