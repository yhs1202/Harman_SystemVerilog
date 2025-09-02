`timescale 1ns / 1ps
module tb_UART_Tx();
    // Assuming a 100MHz clock for 9600 baud rate
    parameter BAUD_DELAY = (100_000_000 / 9600) * 10 * 10;

    reg clk, rst;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    wire tx;

    // Instantiate the UART_Tx module (UART_top == UART_Tx at this level)
    UART_top dut (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx_busy(tx_busy),
        .tx(tx)
    );

    always #5 clk = ~clk;
    
    initial begin
        #0; clk = 0; rst = 1; tx_start = 0;
        tx_data = 8'h31;


        #10; rst = 0;
        #10; tx_start = 1;
        #10; tx_start = 0;
        #(BAUD_DELAY);
        #1000;

        // Wait for transmission to complete
        wait(tx_busy == 0);
        $stop;
    end

    // // Test vector generation and send to UART
    // task test_vector_gen(input start, input [7:0] tx_data);
    //     tx_data = data;
    //     #10; tx_start = start;
    //     #10; tx_start = 0;
    //     #(BAUD_DELAY);
    // endtask

    // // RX verification
    // task rx_verification();
    //     // Implement RX verification logic here
    // endtask
endmodule
