`timescale 1ns/1ps

module i2c_slave #(
    parameter SLAVE_ADDR = 7'b101_0000, // example: 0x50
    parameter MEM_SIZE   = 16           // Memory size in bytes
) (
    // Global Signals
    input logic clk,
    input logic rst,

    // external memory to AXI Bridge
    output logic start_detect,      // Start condition detected
    output logic stop_detect,       // Stop condition detected
    output logic rw_mode,           // 1 = Read, 0 = Write
    output logic [7:0] rx_data,     // Received data byte (Master -> "Slave")
    output logic rx_valid,
    input logic [7:0] tx_data,      // Transmit data byte ("Slave" -> Master), Stored in memory
    input logic tx_valid,

    // I2C Signals
    inout tri sda,
    inout tri scl
);

    // Implementation of I2C Slave functionality would go here.
    // This is a placeholder for the actual slave logic.

    logic sda_in, scl_in;
    assign sda_in = sda;
    assign scl_in = scl;

    logic sda_out_en;   // 1: to drive SDA low
    assign sda = sda_out_en ? 1'b0 : 1'bz;

    // scl, sda synchronizers for edge detection
    logic [1:0] scl_sync; // {scl_q, scl_d}
    logic [1:0] sda_sync; // {sda_q, sda_d}

    always_ff @(posedge clk, posedge rst) begin : synchronizers
        if (rst) begin
            // Reset synchronizers, initialize to high (idle state)
            scl_sync <= 2'b11;
            sda_sync <= 2'b11;
        end else begin
            scl_sync <= {scl_sync[0], scl_in};
            sda_sync <= {sda_sync[0], sda_in};
        end
    end

    // Edge detectors
    wire scl_rise = (scl_sync[1:0] == 2'b01);     // 0->1
    wire scl_fall = (scl_sync[1:0] == 2'b10);     // 1->0
    

    // Start/Stop condition detection
    assign start_detect = (state == IDLE) ? (sda_sync[1:0] == 2'b10) && scl_sync[1] : 0;        // SDA: 1->0 while SCL=1
    assign stop_detect  = (state == WRITE_ACK) ? (sda_sync[1:0] == 2'b01) && scl_sync[1] : 0;   // SDA: 0->1 while SCL=1


    // State enumeration
    typedef enum logic [2:0] {
        IDLE,
        ADDRESS,
        ADDR_ACK,
        WRITE_DATA,
        WRITE_ACK,
        READ_DATA,
        READ_ACK
    } state_t;

    state_t state;


    logic [7:0] shift_reg;
    logic [3:0] bit_count;  // up to 9 bits (DATA + ACK)
    
    // FSM
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            sda_out_en <= 0;
            rw_mode <= 0;
            rx_data <= 0;
            rx_valid <= 0;
            shift_reg <= 0;
            bit_count <= 0;

        end else begin
            rx_valid <= 0;
            case (state)
                IDLE: begin // Wait for START
                    sda_out_en <= 0;
                    if (start_detect) state <= ADDRESS;
                end

                ADDRESS: begin // Sample address + R/W on SCL rising edge
                    if (scl_rise) begin
                        shift_reg <= {shift_reg[6:0], sda_in};
                        bit_count <= bit_count + 1;
                        if (bit_count == 7) begin
                            rw_mode <= sda_in;     // R/W, Same with bit0
                            bit_count <= 0;
                            if (shift_reg[6:0] == SLAVE_ADDR)     // Slave addr match
                                state <= ADDR_ACK;
                            else
                                state <= IDLE; // ignore
                        end
                    end
                end

                ADDR_ACK: begin // ACK for address to master (SDA low on SCL fall)
                    if (scl_fall) begin
                        sda_out_en <= 1; // ACK
                        if (bit_count != 0) begin // 1 i2c_clk delay for ACK
                            // if (scl_rise) begin // Release SDA after ACK
                            bit_count <= 0;
                            if (rw_mode) begin // READ
                                state <= READ_DATA;
                                shift_reg <= (tx_valid) ? tx_data : 8'hff; // Load data to send if READ
                            end else begin
                                sda_out_en <= 0; // release SDA
                                state <= WRITE_DATA;
                            end
                            // end
                        end else begin
                        // if (scl_rise) 
                            bit_count <= bit_count + 1;
                        end
                    end
                end

                WRITE_DATA: begin // Sample received data on SCL rising edge
                    if (scl_rise) begin
                        shift_reg <= {shift_reg[6:0], sda_in};
                        bit_count <= bit_count + 1;

                        if (bit_count == 8) begin
                            rx_data <= {shift_reg[6:0], sda_in};
                            rx_valid <= 1;  // Indicate data received
                            bit_count <= 0;
                            state <= WRITE_ACK;
                        end
                    end
                end

                WRITE_ACK: begin // ACK for received data to master (SDA low on SCL fall)
                    if (scl_fall) begin
                        sda_out_en <= 1; // ACK
                        if (bit_count != 0) begin
                            sda_out_en <= 0;
                            // state <= IDLE;
                            bit_count <= 0;
                            if (stop_detect) // Stop condition detected
                                state <= IDLE;
                            else begin
                                rx_valid <= 0;
                                state <= WRITE_DATA;    // Ready for next byte
                            end
                        end 
                    end else begin
                            bit_count <= bit_count + 1;
                    end
                end

                READ_DATA: begin // Drive data bits to master on SCL falling edge
                    // shift_reg <= tx_data; // Load data to send
                    if (scl_fall) begin
                        // sda_out_en <= 1; // Drive data bit
                        // if (bit_count == 0) begin 
                        //     if (tx_valid) shift_reg <= tx_data;   // Load new data byte at start
                        //     else shift_reg <= 8'hff; // If no data, send 0x00
                        // end
                        if (bit_count != 7) begin
                            sda_out_en <= !shift_reg[7];  // Drive MSB first
                            shift_reg <= {shift_reg[6:0], 1'b0}; // Shift left, fill with 0
                            bit_count <= bit_count + 1;
                        end else begin
                            bit_count <= 0;
                            state <= READ_ACK;
                        end
                    end
                end

                READ_ACK: begin // Sample ACK/NACK from master on SCL rising edge
                    sda_out_en <= 0; // Release SDA after sending data

                    if (scl_rise) begin
                        if (bit_count != 0) begin
                            if (!tx_valid) begin
                                state <= IDLE; // No more data to send
                            end else begin
                                if (sda_in == 1) begin 
                                    state <= IDLE;      // NACK received -> stop reading
                                end else begin
                                    state <= READ_DATA; // ACK received -> continue reading
                                end
                            end
                        end else begin
                            bit_count <= bit_count + 1;
                        end
                    end
                end
            endcase
        end
    end

endmodule