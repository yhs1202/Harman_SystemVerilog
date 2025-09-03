`timescale 1ns / 1ps
module tb_UART_Rx();
    reg clk, rst, rx;
    wire [7:0] rx_data;
    wire rx_done;

    // for verification
    reg [7:0] transmitted_data;
    wire tx_busy;

    integer bit_cnt = 0;

    parameter BAUD_RATE = 9600;
    parameter CLOCK_PERIOD_NS = 10; // 100MHz
    parameter CLOCK_PER_BIT = 10416;    // 10416 clock cycles per bit
    parameter BIT_PERIOD = CLOCK_PER_BIT * CLOCK_PERIOD_NS;

    UART_top dut (
        // tx -> will not connect at this time
        .clk(clk),
        .rst(rst),
        .tx_start(),
        .tx_data(),
        .rx(rx),
        .tx_busy(),
        .tx(),
        .rx_data(rx_data),
        .rx_done(rx_done)
    );

    always #5 clk = ~clk;

    initial begin
        #0; clk = 0; rst = 1; rx = 1;   // rx idle
        #10; rst = 0; transmitted_data = 8'h31;
        #100;

        // send to uart rx
        // start bit
        rx = 0; // rx low -> start bit
        #(BIT_PERIOD);
        for (bit_cnt = 0; bit_cnt < 8; bit_cnt = bit_cnt + 1) begin
            rx = transmitted_data[bit_cnt];
            #(BIT_PERIOD);
        end

        // stop
        rx = 1; // rx high -> stop bit
        #(BIT_PERIOD);
        #1000;
        $stop;
    end
    
endmodule
