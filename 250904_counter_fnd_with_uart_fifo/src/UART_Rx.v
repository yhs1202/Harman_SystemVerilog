`timescale 1ns/1ps

module UART_Rx (
    input clk,
    input rst,
    input b_tick,
    input rx,
    output [7:0] rx_data,
    output rx_busy,
    output rx_done
    );

    localparam [1:0] IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] c_state, n_state;
    reg [3:0] c_b_tick_cnt, n_b_tick_cnt;
    reg [2:0] c_bit_cnt, n_bit_cnt;
    reg [7:0] c_rx_data, n_rx_data;
    reg c_rx_busy, n_rx_busy;
    reg c_rx_done, n_rx_done;

    // output signals
    assign rx_data = c_rx_data;
    assign rx_busy = c_rx_busy;
    assign rx_done = c_rx_done;

    // state register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            c_b_tick_cnt <= 0;
            c_bit_cnt <= 0;
            c_rx_data <= 8'h00;
            c_rx_busy <= 1'b0;
            c_rx_done <= 1'b0;
        end else begin
            c_state <= n_state;
            c_b_tick_cnt <= n_b_tick_cnt;
            c_bit_cnt <= n_bit_cnt;
            c_rx_data <= n_rx_data;
            c_rx_busy <= n_rx_busy;
            c_rx_done <= n_rx_done;
        end
    end

    // next state logic
    always @(*) begin
        n_state = c_state;
        n_b_tick_cnt = c_b_tick_cnt;
        n_bit_cnt = c_bit_cnt;
        n_rx_data = c_rx_data;
        n_rx_busy = c_rx_busy;
        n_rx_done = c_rx_done;
        case (c_state)
            IDLE: begin
                n_rx_done = 1'b0; // clear done flag
                if (rx == 0) begin // start bit detected
                    n_b_tick_cnt = 0; // reset tick counter
                    n_bit_cnt = 0;
                    n_rx_busy = 1'b1; // set busy flag
                    n_state = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (c_b_tick_cnt == 4'd7) begin // wait for half a bit time
                        n_state = DATA;
                        n_b_tick_cnt = 0;
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (c_b_tick_cnt == 15) begin // read data bit
                    // rx -> lsb first
                    // bit0 -> 76543210 -> rx7654321
                    n_rx_data = {rx, c_rx_data[7:1]};
                    n_b_tick_cnt = 0;
                    if (c_bit_cnt == 7) begin
                        n_state = STOP; // go to stop state after 8 bits
                    end else begin
                        n_bit_cnt = c_bit_cnt + 1;
                        end
                end else begin
                    n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    if (c_b_tick_cnt == 15) begin // wait for stop bit
                        n_rx_done = 1'b1; // signal that reception is done
                        n_rx_busy = 1'b0; // clear busy flag
                        n_state = IDLE; // go back to idle state
                    end else begin
                        n_b_tick_cnt = c_b_tick_cnt + 1;
                    end
                end
            end
        endcase
    end
endmodule