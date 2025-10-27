`timescale 1ns / 1ps

module UART_CORE #(
    parameter CLK_FREQ = 100_000_000,  // FPGA clock (Hz)
    parameter BAUD     = 9600          // UART baud rate
)(
    input  logic clk,
    input  logic rst,

    // From APB interface
    input  logic [7:0]  tx_data,
    input  logic        tx_wr,        // TX FIFO write enable
    output logic        tx_empty,
    output logic        tx_busy,
    output logic        TX,

    output logic [7:0]  rx_data,
    input  logic        rx_rd,        // RX FIFO read enable
    output logic        rx_valid,
    input  logic        RX
);

    // Baud Rate Generator
    localparam integer DIVIDER = CLK_FREQ / BAUD;
    logic [$clog2(DIVIDER)-1:0] baud_cnt;
    logic baud_tick;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            baud_cnt <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_cnt == DIVIDER - 1) begin
                baud_cnt <= 0;
                baud_tick <= 1;
            end else begin
                baud_cnt <= baud_cnt + 1;
                baud_tick <= 0;
            end
        end
    end


    // TX FIFO / RX FIFO
    logic [7:0] tx_fifo_dout;
    logic tx_fifo_rd, tx_fifo_empty, tx_fifo_full;

    fifo_top TX_FIFO (
        .clk(clk), .rst(rst),
        .w_en(tx_wr), .r_en(tx_fifo_rd),
        .w_data(tx_data), .r_data(tx_fifo_dout),
        .empty(tx_fifo_empty), .full(tx_fifo_full)
    );

    assign tx_empty = tx_fifo_empty;

    logic [7:0] rx_fifo_din;
    logic rx_fifo_wr, rx_fifo_empty, rx_fifo_full;

    fifo_top RX_FIFO (
        .clk(clk), .rst(rst),
        .w_en(rx_fifo_wr), .r_en(rx_rd),
        .w_data(rx_fifo_din), .r_data(rx_data),
        .empty(rx_fifo_empty), .full(rx_fifo_full)
    );

    assign rx_valid = !rx_fifo_empty;



    // UART TX Logic
    logic [9:0] tx_shift;
    logic [3:0] tx_bit_cnt;
    logic tx_en;

    typedef enum logic [1:0] {TX_IDLE, TX_START, TX_SEND} tx_state_t;
    tx_state_t tx_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            TX <= 1'b1;
            tx_state <= TX_IDLE;
            tx_bit_cnt <= 0;
            tx_fifo_rd <= 0;
            tx_busy <= 0;
        end else begin
            tx_fifo_rd <= 0;
            if (baud_tick) begin
                case (tx_state)
                    TX_IDLE: if (!tx_fifo_empty) begin
                        tx_fifo_rd <= 1'b1;
                        tx_busy <= 1;
                        tx_state <= TX_START;
                    end
                    TX_START: begin
                        tx_shift <= {1'b1, tx_fifo_dout, 1'b0};
                        tx_bit_cnt <= 0;
                        tx_state <= TX_SEND;
                    end
                    TX_SEND: begin
                        TX <= tx_shift[tx_bit_cnt];
                        tx_bit_cnt <= tx_bit_cnt + 1;
                        if (tx_bit_cnt == 9) begin
                            tx_state <= TX_IDLE;
                            tx_busy <= 0;
                            TX <= 1'b1;
                        end
                    end
                endcase
            end
        end
    end
    
    // UART RX Logic
    logic [3:0] rx_bit_cnt;
    logic [7:0] rx_shift;
    logic [15:0] sample_cnt;
    logic rx_sample_tick;
    typedef enum logic [1:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state_t;
    rx_state_t rx_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_state <= RX_IDLE;
            rx_bit_cnt <= 0;
            sample_cnt <= 0;
            rx_fifo_wr <= 0;
        end else begin
            rx_fifo_wr <= 0;

            case (rx_state)
                RX_IDLE: begin
                    if (!RX) begin  // Start bit detected
                        rx_state <= RX_START;
                        sample_cnt <= DIVIDER/2;
                    end
                end

                RX_START: begin
                    if (sample_cnt == 0) begin
                        if (!RX) begin
                            rx_state <= RX_DATA;
                            rx_bit_cnt <= 0;
                            sample_cnt <= DIVIDER;
                        end else
                            rx_state <= RX_IDLE;
                    end else
                        sample_cnt <= sample_cnt - 1;
                end

                RX_DATA: begin
                    if (sample_cnt == 0) begin
                        rx_shift[rx_bit_cnt] <= RX;
                        rx_bit_cnt <= rx_bit_cnt + 1;
                        sample_cnt <= DIVIDER;
                        if (rx_bit_cnt == 7)
                            rx_state <= RX_STOP;
                    end else
                        sample_cnt <= sample_cnt - 1;
                end

                RX_STOP: begin
                    if (sample_cnt == 0) begin
                        if (RX && !rx_fifo_full) begin
                            rx_fifo_din <= rx_shift;
                            rx_fifo_wr <= 1;
                        end
                        rx_state <= RX_IDLE;
                    end else
                        sample_cnt <= sample_cnt - 1;
                end
            endcase
        end
    end

endmodule
