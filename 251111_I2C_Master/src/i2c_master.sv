`timescale 1ns / 1ps

// I2C Controller Module
// Author: Hoseung Yoon
// Description: 
// This module implements an I2C controller that handles address, data input/output, 
// and multi-byte transactions.
// System Clock: 100 MHz, I2C Clock: 100 kHz (1/1000, configurable via DIVIDE_BY)

module i2c_master(
    // global signals
    input  logic clk,
    input  logic rst,

    // I2C transaction signals
    input  logic [6:0] addr,
    input  logic [7:0] tx_data,     // input data to write (master -> slave)
    input  logic i2c_en,            // I2C enable signal
    input  logic rw,                // 0: write, 1: read

    // for multi-byte transactions
    input  logic data_valid,        // Indicates that next byte is ready to send (for write)
    output logic data_next,         // Indicates request pulse for next byte 
    input  logic read_last,         // If last byte during read, set to 1

    output logic [7:0] rx_data,     // Received output data during read (slave -> master)
    output logic ready,             // Master idle flag (ready for next transaction)

    // I2C bus (open-drain)
    inout  wire  i2c_sda,
    inout  wire  i2c_scl
);

    // State enumeration
    typedef enum logic [3:0] {
        IDLE,       // Waiting for I2C enable
        START,      // Start condition (SDA low while SCL high)
        ADDRESS,    // Send 7-bit address + R/W bit
        READ_ACK,   // after address byte, check ACK from slave
        WRITE_DATA, // write byte to slave (MSB first)
        READ_ACK2,  // after data write, check ACK from slave and decide next
        READ_DATA,  // read byte from slave
        WRITE_ACK,  // after read data, send ACK/NACK
        STOP
    } state_t;

    localparam DIVIDE_BY = 4; // divider for I2C clock

    
    // Internal registers
    state_t state;

    logic [7:0] tx_buf;   // write data buffer
    logic [7:0] addr_buf; // address + R/W buffer
    logic [3:0] byte_cnt; // for multi-byte count


    logic [2:0] bit_counter;

    assign ready = ((rst == 0) && (state == IDLE)) ? 1 : 0;


    // I2C clock generation
    reg [7:0] i2c_clk_cnt = 0;
    reg i2c_clk = 1;
    
    always_ff @(posedge clk) begin : I2C_CLK_GEN
        if (i2c_clk_cnt == (DIVIDE_BY/2) - 1) begin
        i2c_clk <= ~i2c_clk;
        i2c_clk_cnt <= 0;
        end else i2c_clk_cnt <= i2c_clk_cnt + 1;
    end

    
    // SCL enable control
    // Keep SCL high during IDLE and STOP states
    reg i2c_scl_enable = 0;
    assign i2c_scl = (i2c_scl_enable == 0) ? 1'b1 : i2c_clk;
    
    always_ff @(posedge i2c_clk or posedge rst) begin
        if (rst) begin
        i2c_scl_enable <= 0;
        end else begin
            if ((state == IDLE) || (state == STOP))
                i2c_scl_enable <= 0;
            else
                i2c_scl_enable <= 1;
        end
    end


    // SDA Control (negedge i2c_clk: change SDA when SCL is low)
    reg sda_out;
    reg write_enable;
    assign i2c_sda = (write_enable) ? sda_out : 1'bz;

    always_ff @(negedge i2c_clk or posedge rst) begin
        if (rst) begin
            write_enable <= 1;
            sda_out      <= 1;
        end else begin
            case (state)
            START: begin
                write_enable <= 1;
                sda_out      <= 0; // START: SCL:H, SDA:L
            end
            ADDRESS: begin
                write_enable <= 1;
                sda_out      <= addr_buf[7]; // SLA+R/W MSB-first
            end
            READ_ACK: begin
                write_enable <= 0;   // Slave READ ACK/NACK
            end
            WRITE_DATA: begin
                write_enable <= 1;
                sda_out      <= tx_buf[7]; // Data MSB-first
            end
            READ_ACK2: begin
                write_enable <= 0;   // Slave READ ACK/NACK
            end
            READ_DATA: begin
                write_enable <= 0;   // Slave drives data
            end
            WRITE_ACK: begin    // Only READ ACK(0)/NACK(1)
                write_enable <= 1;
                sda_out      <= (read_last) ? 1'b1 : 1'b0; // Last=NACK(1), continue=ACK(0)
            end
            STOP: begin
                write_enable <= 1;
                sda_out      <= 1;  // STOP: SCL:H, SDA:H
            end
            endcase
        end
    end

    // Main FSM
    always_ff @(posedge i2c_clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            {rx_data, tx_buf, addr_buf} <= 0;
            {data_next, bit_counter, byte_cnt} <= 0;
        end else begin
            data_next <= 1'b0; // Default clear for pulse signal
            case (state)
                IDLE: begin
                    if (i2c_en) begin
                        addr_buf <= {addr, rw};
                        tx_buf <= tx_data;
                        rx_data <= 0;
                        bit_counter <= 0;
                        state <= START;
                    end
                end

                START: begin
                    bit_counter <= 0;
                    state <= ADDRESS;
                end

                ADDRESS: begin
                    if (bit_counter != 7) begin
                        bit_counter <= bit_counter + 1;
                        addr_buf <= {addr_buf[6:0], 1'b0};  // shift left
                    end
                    else state <= READ_ACK;
                end

                READ_ACK: begin
                    if (i2c_sda == 1'b0) begin  // SLAVE ACK Received
                        bit_counter <= 0;
                        state <= (addr_buf[7] == 1'b0) ? WRITE_DATA : READ_DATA; // WRITE or READ
                    end else begin
                        state <= STOP; // NACK -> STOP
                    end
                end

                WRITE_DATA: begin
                    if (bit_counter != 7) begin
                        bit_counter <= bit_counter + 1;
                        tx_buf <= {tx_buf[6:0], 1'b0};  // shift left
                    end
                    else state <= READ_ACK2;
                end

                // Check ACK after write data
                // Decide next action based on data_valid
                READ_ACK2: begin
                    if (i2c_sda == 1'b0) begin  // SLAVE ACK
                        if (data_valid) begin // Next byte available
                            byte_cnt  <= byte_cnt + 1;  // count written bytes
                            tx_buf <= tx_data;          // load next data
                            data_next <= 1'b1;          // request next byte (pulse)
                            bit_counter <= 0;
                            state <= WRITE_DATA;
                        end else begin // No more data -> STOP
                            state <= STOP;
                        end
                    end else begin  // NACK -> STOP
                        state <= STOP;
                    end
                end

                READ_DATA: begin
                    rx_data <= {rx_data[6:0], i2c_sda};    // Sample data bit
                    if (bit_counter == 7) state <= WRITE_ACK; // last bit received -> send ACK/NACK
                    else bit_counter <= bit_counter + 1;
                end

                // Send ACK/NACK after read data
                WRITE_ACK: begin
                    if (read_last) begin    // last byte -> NACK then STOP
                        state <= STOP;
                    end else begin    // More data to read -> ACK then next byte
                        bit_counter <= 0;
                        data_next <= 1'b1; // Notify "this byte has been read" (FIFO push, etc. if needed)
                        byte_cnt  <= byte_cnt + 1;  // count read bytes
                        state <= READ_DATA;
                    end
                end

                // SDA goes High while SCL High
                STOP: begin
                    byte_cnt <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end


endmodule
