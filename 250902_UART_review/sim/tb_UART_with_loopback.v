`timescale 1ns / 1ps
module tb_UART_with_loopback();
    parameter BAUD_RATE = 9600;
    parameter CLOCK_PERIOD_NS = 10; // 100MHz
    parameter CLOCK_PER_BIT = 10416;    // 10416 clock cycles per bit
    parameter BIT_PERIOD = CLOCK_PER_BIT * CLOCK_PERIOD_NS;

    reg clk, rst;
    reg rx; // tx_start with loopback
    reg [7:0] send_data;
    reg [7:0] receive_data;

    reg [7:0] pass_count, fail_count;

    // wire [7:0] rx_data;
    wire tx;

    integer i = 0;

    UART_with_loopback UUT (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .tx(tx)
    );

    always #5 clk = ~clk;

    initial begin
        #0; clk = 0; rst = 1; rx = 1; 
        send_data = 0; receive_data = 0;
        pass_count = 0; fail_count = 0;
        #10; rst = 0;
        
        // Test case: Send and receive a byte
        for (i = 0; i < 256 ; i = i + 1) begin
            send_data = i;
            single_uart_test(send_data);
        end
        #1000


        $stop;
    end

    task send_uart (
        input [7:0] send_data
    );
        integer i;
        begin
            receive_data = send_data;
            // Start bit
            rx = 0;
            #(BIT_PERIOD);

            // Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = send_data[i];
                #(BIT_PERIOD);
            end

            // Stop bit
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    task receive_uart();
        integer i;
        begin
            @(negedge tx);
            #(BIT_PERIOD * 0.5); // Middle of start bit
            if (tx == 0) begin
                #(BIT_PERIOD); // Middle of first data bit
                for (i = 0; i < 8; i = i + 1) begin
                    receive_data[i] = tx;
                    #(BIT_PERIOD);
                end
                #(BIT_PERIOD); // Stop bit
                $display("Received Data: %h", receive_data);
                if (receive_data == send_data) begin
                    $display("Test Passed");
                    pass_count = pass_count + 1;
                end else begin
                    $display("Test Failed");
                    fail_count = fail_count + 1;
                end
            end
        end
    endtask

    task single_uart_test(input [7:0] send_data);
        fork
            send_uart(send_data);
            receive_uart();
        join
    endtask
endmodule
