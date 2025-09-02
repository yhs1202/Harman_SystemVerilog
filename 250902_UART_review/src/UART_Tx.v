`timescale 1ns / 1ps
module UART_Tx(
    input clk, rst,
    input tx_start,
    input b_tick,
    input [7:0] tx_data,
    output tx_busy,
    output tx
);

    localparam IDLE = 2'b00,
               START = 2'b01,
               DATA = 2'b10,
               STOP = 2'b11;

    reg [1:0] c_state, n_state;
    reg tx_busy_reg, tx_busy_next;
    reg [7:0] tx_data_reg, tx_data_next;
    reg tx_reg, tx_next;
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;  // 16
    reg [2:0] bit_cnt_reg, bit_cnt_next;        // 8


    
    assign tx_busy = tx_busy_reg;
    assign tx = tx_reg;

    // State register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            tx_busy_reg <= 0;
            tx_data_reg <= 0;
            tx_reg <= 1;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg <= 0;

        end
        else begin
            c_state <= n_state;
            tx_busy_reg <= tx_busy_next;
            tx_data_reg <= tx_data_next;
            tx_reg <= tx_next;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg <= bit_cnt_next;
        end
    end

    // Next-state logic
    always @(*) begin
        n_state = c_state;
        tx_busy_next = tx_busy_reg;
        tx_data_next = tx_data_reg;
        tx_next = tx_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        case (c_state)
            IDLE: begin
                tx_next = 1;
                tx_busy_next = 0;
                if (tx_start) begin
                    tx_data_next = tx_data;
                    n_state = START;
                end
            end
            START: begin
                tx_next = 0;
                tx_busy_next = 1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        n_state = DATA;
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            DATA: begin
                tx_next = tx_data_reg[0];
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;    // Reset bit tick counter
                            n_state = STOP;
                        end
                        else begin
                            b_tick_cnt_next = 0;    // Reset bit tick counter
                            bit_cnt_next = bit_cnt_reg + 1;
                            tx_data_next = tx_data_reg >> 1;
                        end
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                tx_next = 1;
                if (b_tick) begin
                    if (b_tick_cnt_next == 15) begin
                        b_tick_cnt_next = 0;
                        n_state = IDLE;
                    end
                    else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule
