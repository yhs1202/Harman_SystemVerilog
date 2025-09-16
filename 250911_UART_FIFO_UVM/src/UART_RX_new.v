`timescale 1ns/1ps
module UART_Rx_new (
    input clk,
    input rst,
    input b_tick,
    input rx,
    output [7:0] rx_data,
    output rx_done
);

    localparam [1:0] IDLE = 2'b00,
                     START = 2'b01,
                     DATA = 2'b10,
                     STOP = 2'b11;

    reg [1:0] c_state, n_state;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg rx_done_reg, rx_done_next;

    assign rx_data = rx_data_reg;
    assign rx_done = rx_done_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;
            rx_data_reg <= 0;
            rx_done_reg <= 0;
        end else begin
            c_state <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
            rx_data_reg <= rx_data_next;
            rx_done_reg <= rx_done_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = rx_done_reg;

        case (c_state)
            IDLE: begin
                    rx_done_next = 0;
                if (rx == 0) begin
                    b_tick_cnt_next = 0;
                    bit_cnt_next = 0;
                    n_state = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 8) begin
                        n_state = DATA;
                        b_tick_cnt_next = 0;
                        bit_cnt_next = 0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        rx_data_next = {rx, rx_data_reg[7:1]};  // Shift in new bit
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;
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
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        rx_done_next = 1; // Set done flag
                        n_state = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule