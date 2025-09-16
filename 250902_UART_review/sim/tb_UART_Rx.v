`timescale 1ns / 1ps
module tb_UART_Rx();
    parameter BAUD_RATE = 9600;
    parameter CLOCK_PERIOD_NS = 10; // 100MHz
    parameter CLOCK_PER_BIT = 10416;    // 10416 clock cycles per bit
    parameter BIT_PERIOD = CLOCK_PER_BIT * CLOCK_PERIOD_NS;

    reg clk, rst, rx;
    wire [7:0] rx_data;
    wire rx_done;

    // for verification
    reg [7:0] expected_data;
    reg [7:0] transmitted_data;
    wire tx_busy;

    reg [7:0] pass_count;
    reg [7:0] fail_count;

    integer bit_cnt = 0;
    integer i = 0;


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
        transmitted_data = 0;
        pass_count = 0; fail_count = 0;
        #10; rst = 0;
        #100;

        // send to uart rx
        // start bit
        // rx = 0; // rx low -> start bit
        // #(BIT_PERIOD);
        // for (bit_cnt = 0; bit_cnt < 8; bit_cnt = bit_cnt + 1) begin
        //     rx = transmitted_data[bit_cnt];
        //     #(BIT_PERIOD);
        // end

        // stop
        // rx = 1; // rx high -> stop bit
        #(BIT_PERIOD);

        $display("UART RX tb started");
        $display("BAUD_RATE: %d", BAUD_RATE);
        $display("CLOCK_PER_BIT: %d", CLOCK_PER_BIT);
        $display("BIT_PERIOD: %d", BIT_PERIOD);
        for (i = 0; i < 256; i = i + 1) begin
            transmitted_data = $random() % 256;
            single_uart_rx_test(transmitted_data);
        end
        #1000;
        $stop;
    end

    // Test vector generation and send to UART
    task send(input [7:0] transmitted_data);
        begin
            expected_data = transmitted_data;
            #10;

            rx = 0;
            #(BIT_PERIOD);
            for (bit_cnt = 0; bit_cnt < 8; bit_cnt = bit_cnt + 1) begin
                rx = transmitted_data[bit_cnt];
                #(BIT_PERIOD);
            end

            // stop bit
            rx = 1;
            #(BIT_PERIOD);
            #10000;
        end
    endtask


    // RX verification
    task transmit_uart();
        begin
            $display("transmit_uart start");
            // transmitted_data = 0;
            @(negedge rx);  // wait for start bit (falling edge)
            // middle of start bit
            #(BIT_PERIOD / 2);

            // start bit pass/fail
            if (rx) begin
                // fail
                $display("RX verification failed: start bit is high");
                // fail_count = fail_count + 1;
            end

            @(negedge rx_done);
            transmitted_data = rx_data;

            // transmitted data bits
            // // for (bit_count = 0; bit_count < 8; bit_count = bit_count + 1) begin
            //     // #(BIT_PERIOD);
            //     // rx = transmitted_data[bit_count];
            // // end

            // check stop bit
            // #(BIT_PERIOD);
            if (!rx) begin
                $display("RX verification failed: stop bit is low");
                // fail_count = fail_count + 1;
            end

            #(BIT_PERIOD / 2);
            // compare data
            if (transmitted_data !== expected_data) begin
                $display("RX verification failed: expected %h, got %h", expected_data, transmitted_data);
                fail_count = fail_count + 1;
            end else begin
                pass_count = pass_count + 1;
            end
        end
    endtask

    task single_uart_rx_test(input [7:0] transmitted_data);
        fork
            send(transmitted_data);
            transmit_uart();
        join
    endtask
    
endmodule
