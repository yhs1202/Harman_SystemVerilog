`timescale 1ns / 1ps

// I2C Master Core Module
// Author: Hoseung Yoon
// Description: This module implements an I2C master controller.
// System Clock Frequency: 100 MHz, I2C Clock Frequency: 100 kHz

module i2c_master (
    // global signals
    input logic clk,
    input logic rst,

    // I2C control signals
    input logic i2c_en,     // I2C transaction enable
    input logic i2c_start,  // I2C start condition trigger
    input logic i2c_stop,   // I2C stop condition trigger

    // I2C transaction signals
    // Write data interface
    input logic [7:0] tx_data,
    input logic tx_valid,
    output logic tx_ready,
    output logic tx_done,

    // Read data interface
    input logic rx_ready,
    output logic [7:0] rx_data,
    output logic rx_valid,
    output logic rx_done,

    output logic busy,

    // I2C bus (open-drain)
    inout tri scl,
    inout tri sda

);

    // I2C timing parameters
    localparam int COUNT_HALF_PERIOD = 500; // 100MHz -> 100kHz (SCL)
    localparam int COUNT_DATA_DURATION = 250;


    // I2C bus signals (open-drain)
    logic sda_drv, scl_drv;     // Drive signals
    logic sda_in;               // Read SDA line
    assign sda = sda_drv ? 1'bz : 1'b0;
    assign scl = scl_drv ? 1'bz : 1'b0;
    assign sda_in = sda;

    // State enumeration
    typedef enum logic [3:0] {
        IDLE,
        HOLD,
        START1, START2,
        W_DATA1, W_DATA2, W_DATA3, W_DATA4,
        R_DATA1, R_DATA2, R_DATA3, R_DATA4,
        ACK1, ACK2,
        STOP1, STOP2
    } state_t;

    state_t state_reg, state_next;



    // Data buffers
    logic [7:0] tx_buf_reg, tx_buf_next;
    logic [7:0] rx_buf_reg, rx_buf_next;
    logic [3:0] bit_cnt_reg, bit_cnt_next; // Bit counter for 8 bits


    // Tick generator for I2C timing
    logic tick;
    logic [9:0] clk_cnt;    // up to 1000

    always_ff @( posedge clk, posedge rst ) begin : clk_gen
        if (rst) clk_cnt <= 0;
        else if (tick) clk_cnt <= 0;
        else if (state_reg != IDLE) clk_cnt <= clk_cnt + 1;
        else clk_cnt <= 0;
    end

    assign tick = 
        ((state_reg inside {START1, START2, STOP1, STOP2}) && (clk_cnt == COUNT_HALF_PERIOD-1)) ||
        ((state_reg inside {W_DATA1, W_DATA2, W_DATA3, W_DATA4, R_DATA1, R_DATA2, 
                            R_DATA3, R_DATA4, ACK1, ACK2}) && (clk_cnt == COUNT_DATA_DURATION-1));


    // State transition
    always_ff @(posedge clk or posedge rst) begin : state_ff
        if (rst) begin
            state_reg <= IDLE;
            tx_buf_reg <= 8'h00;
            rx_buf_reg <= 8'h00;
            bit_cnt_reg <= 4'd0;
        end else begin
            state_reg <= state_next;
            tx_buf_reg <= tx_buf_next;
            rx_buf_reg <= rx_buf_next;
            bit_cnt_reg <= bit_cnt_next;
        end
    end


    // Next state logic
    always_comb begin : state_comb
        state_next = state_reg;
        tx_buf_next = tx_buf_reg;
        rx_buf_next = rx_buf_reg;
        bit_cnt_next = bit_cnt_reg;

        tx_ready = 1'b0;
        rx_valid = 1'b0;
        tx_done = 1'b0;
        rx_done = 1'b0;

        busy = 1'b0;
        sda_drv = 1'b0;
        scl_drv = 1'b0;

        case (state_reg)
            IDLE: begin
                busy = 1'b0;
                if (i2c_en) state_next = HOLD;
            end

            HOLD: begin
                busy = 1'b1;
                tx_ready = 1'b1;
                unique case ({i2c_start, i2c_stop})
                    2'b10: state_next = START1;
                    2'b01: state_next = STOP1;
                    2'b00: begin 
                        if (tx_valid) begin
                            state_next = W_DATA1;  // for burst write
                            tx_buf_next = tx_data;
                            bit_cnt_next = 0;
                        end 
                    end
                    2'b11: begin
                        if (rx_ready) begin
                            state_next = R_DATA1;
                            bit_cnt_next = 0;
                        end
                    end
                endcase
            end

            START1: begin
                sda_drv = 1'b1;
                scl_drv = 1'b0;
                if (tick) state_next = START2;
            end

            START2: begin
                sda_drv = 1'b1;
                scl_drv = 1'b1;    // Start condition: SDA goes low while SCL is high
                if (tick) state_next = HOLD;
            end

            W_DATA1: begin
                sda_drv = tx_buf_reg[7];
                scl_drv = 1'b1;
                if (tick) state_next = W_DATA2;
            end

            W_DATA2: begin
                sda_drv = tx_buf_reg[7];
                scl_drv = 1'b0;        // Data bit is set on SDA when SCL is low
                if (tick) state_next = W_DATA3;
            end

            W_DATA3: begin
                sda_drv = tx_buf_reg[7];
                scl_drv = 1'b0;        // Data bit is held on SDA when SCL is low
                if (tick) state_next = W_DATA4;
            end

            W_DATA4: begin
                sda_drv = tx_buf_reg[7];
                scl_drv = 1'b1;
                if (tick) begin
                    if (bit_cnt_reg == 7) state_next = ACK1;
                    else begin
                        tx_buf_next = {tx_buf_reg[6:0], 1'b0};
                        bit_cnt_next = bit_cnt_reg + 1'b1;
                        state_next = W_DATA1;
                    end
                end
            end

            ACK1: begin
                sda_drv = 1'b0; // Release SDA for ACK bit
                scl_drv = 1'b1; 
                if (tick) begin
                    // Optionally check for ACK from slave here using sda_in
                    tx_done = 1'b1;
                    state_next = ACK2;
                end
            end

            ACK2: begin
                sda_drv = 1'b0;
                scl_drv = 1'b0; // Prepare for next operation
                if (tick) state_next = HOLD;
                if (tick) begin
                    // Optionally check for ACK from slave here using sda_in
                    tx_done = 1'b1;
                    state_next = HOLD;
                end
            end


            R_DATA1: begin
                sda_drv = 1'b0; // Release SDA for reading
                scl_drv = 1'b1;
                if (tick) state_next = R_DATA2;
            end

            R_DATA2: begin
                sda_drv = 1'b0;
                scl_drv = 1'b0; // Prepare to read data bit
                if (tick) state_next = R_DATA3;
            end

            R_DATA3: begin
                sda_drv = 1'b0;
                scl_drv = 1'b0;
                if (tick) begin
                    rx_buf_next = {sda_in, rx_buf_reg[6:0]}; // Shift in read bit
                    state_next = R_DATA4;
                end
            end

            R_DATA4: begin
                sda_drv = 1'b0;
                scl_drv = 1'b1;
                if (tick) begin
                    if (bit_cnt_reg == 7) begin
                        rx_valid = 1'b1;
                        rx_done = 1'b1;
                        state_next = ACK1; // Send ACK after reading byte
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1'b1;
                        state_next = R_DATA1;
                    end
                end
            end


            STOP1: begin
                sda_drv = 1'b1;
                scl_drv = 1'b1;
                if (tick) state_next = STOP2;
            end

            STOP2: begin
                sda_drv = 1'b0; // Stop condition: SDA goes high while SCL is high
                scl_drv = 1'b0;
                if (tick) begin
                    tx_done = 1;
                    state_next = IDLE;
                end
            end
        endcase


        // rx_valid pulse generation
        if (state_reg == ACK2 && tick && i2c_start && i2c_stop) begin
            rx_valid = 1'b1;
            rx_done = 1'b1;
        end
        if (rx_valid && rx_ready) rx_valid = 1'b0;
    end
    assign rx_data = rx_buf_reg;

    

endmodule
