`timescale 1ns / 1ps
module tb_UART_Tx();
    // Assuming a 100MHz clock for 9600 baud rate
    parameter BAUD_DELAY = (100_000_000 / 9600) * 10 * 10;
    parameter BAUD_RATE = 9600;
    parameter CLOCK_PERIOD_NS = 10; // 100MHz
    parameter CLOCK_PER_BIT = 10416;    // 10416 clock cycles per bit
    parameter BIT_PERIOD = CLOCK_PER_BIT * CLOCK_PERIOD_NS;

    reg clk, rst;
    reg tx_start;
    reg [7:0] tx_data;
    wire tx_busy;
    wire tx;

    // Verification variable
    reg [7:0] expected_data;
    reg [7:0] received_data;
    reg [7:0] pass_count;
    reg [7:0] fail_count;
    integer bit_count = 0;
    integer i;

    // Instantiate the UART_Tx module
    UART_top dut (
        // rx -> will not connect at this time
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .rx(),

        .tx_busy(tx_busy),
        .tx(tx),
        .rx_data(),
        .rx_done()
    );

    always #5 clk = ~clk;
    
    initial begin
        #0; clk = 0; rst = 1; tx_start = 0; pass_count = 0; fail_count = 0;
         tx_data = 8'h41;
        #10; rst = 0;
        #10; tx_start = 1;
        #10; tx_start = 0;

        #(BAUD_DELAY);
        #10000;
        $stop;

        // verification process
        $display("UART TX tb started");
        $display("BAUD_RATE: %d", BAUD_RATE);
        $display("CLOCK_PER_BIT: %d", CLOCK_PER_BIT);
        $display("BIT_PERIOD: %d", BIT_PERIOD);
        for (i = 0; i < 256; i = i + 1) begin
            tx_data = $random() % 256;
            single_uart_tx_test(tx_data);
        end

        // test task
        // single_uart_tx_test(8'h41);
        #1000;
        $stop;
    end

    // Test vector generation and send to UART
    task send(input [7:0] send_data);
        begin
            expected_data = send_data;
            tx_data = send_data;
            @(negedge clk);
            tx_start = 1'b1;
            @(negedge clk);
            tx_start = 1'b0;

            @(negedge tx_busy);
        end
    endtask


    // RX verification
    task received_uart();
        begin
            $display("received_uart start");
            received_data = 0;
            @(negedge tx);  // wait for start bit (falling edge)
            // middle of start bit
            #(BIT_PERIOD / 2);

            // start bit pass/fail
            if (tx) begin
                // fail
                $display("RX verification failed: start bit is high");
                // fail_count = fail_count + 1;
            end

            // received data bits
            for (bit_count = 0; bit_count < 8; bit_count = bit_count + 1) begin
                #(BIT_PERIOD);
                received_data[bit_count] = tx;
            end

            // check stop bit
            #(BIT_PERIOD);
            if (!tx) begin
                $display("RX verification failed: stop bit is low");
                // fail_count = fail_count + 1;
            end

            // compare data
            if (received_data !== expected_data) begin
                $display("RX verification failed: expected %h, got %h", expected_data, received_data);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end

        end
    endtask

    task single_uart_tx_test(input [7:0] send_data);
        fork
            send(send_data);
            received_uart();
        join
    endtask

endmodule
