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
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg rx_busy_reg, rx_busy_next;
    reg rx_done_reg, rx_done_next;

    // output signals
    assign rx_data = rx_data_reg;
    assign rx_busy = rx_busy_reg;
    assign rx_done = rx_done_reg;

    // state register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            rx_data_reg <= 8'h00;
            rx_busy_reg <= 1'b0;
            rx_done_reg <= 1'b0;
        end else begin
            c_state <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            rx_data_reg <= rx_data_next;
            rx_busy_reg <= rx_busy_next;
            rx_done_reg <= rx_done_next;
        end
    end

    // next state logic
    always @(*) begin
        n_state = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        rx_data_next = rx_data_reg;
        rx_busy_next = rx_busy_reg;
        rx_done_next = rx_done_reg;
        case (c_state)
            IDLE: begin
                rx_done_next = 1'b0; // clear done flag
                if (rx == 0) begin // start bit detected
                    b_tick_cnt_next = 0; // reset tick counter
                    bit_cnt_next = 0;
                    rx_busy_next = 1'b1; // set busy flag
                    n_state = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 4'd7) begin // wait for half a bit time
                        n_state = DATA;
                        b_tick_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin // read data bit
                    // rx -> lsb first
                    // bit0 -> 76543210 -> rx7654321
                    rx_data_next = {rx, rx_data_reg[7:1]};
                    b_tick_cnt_next = 0;
                    if (bit_cnt_reg == 7) begin
                        n_state = STOP; // go to stop state after 8 bits
                    end else begin
                        bit_cnt_next = bit_cnt_reg + 1;
                        end
                end else begin
                    b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin // wait for stop bit
                        rx_done_next = 1'b1; // signal that reception is done
                        rx_busy_next = 1'b0; // clear busy flag
                        n_state = IDLE; // go back to idle state
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule