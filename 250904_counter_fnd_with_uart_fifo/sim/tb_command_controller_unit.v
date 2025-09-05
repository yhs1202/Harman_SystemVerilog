`timescale 1ns / 1ps
module tb_command_controller_unit();
    parameter BAUD_RATE = 9600;
    parameter CLOCK_PERIOD_NS = 10; // 100MHz
    parameter CLOCK_PER_BIT = 10416;    // 10416 clock cycles per bit
    parameter BIT_PERIOD = CLOCK_PER_BIT * CLOCK_PERIOD_NS;

    reg clk, rst;
    reg [7:0] input_data;
    reg rx;
    // reg rx_done;
    reg enable, clear, mode;

    counter_top dut (

    .clk(clk), 
    .rst(rst),
    .mode(mode),        // Btn_R, 0: up, 1: down
    .enable(enable),    // Btn_U, 0: stop, 1: run
    .clear(clear),      // Btn_L
    .rx(rx),
    .tx(tx),
    .fnd_com(),
    .fnd_data()
    );

    always #5 clk = ~clk;

    initial begin
        #0; clk = 0; rst = 1;
        mode = 0; enable = 0; clear = 0;
        // rx_done = 0; 
        input_data = 0;
        #10; rst = 0;
        input_data = "R";
        #100; send(input_data);
        // #10; rx_done = 1;
        // #10; rx_done = 0;

        #(BIT_PERIOD / 2);
        force tb_command_controller_unit.dut.U_COUNTER_CONTROLLER_UNIT.btn_clear = 1;
        #10;
        release tb_command_controller_unit.dut.U_COUNTER_CONTROLLER_UNIT.btn_clear;
        #(BIT_PERIOD / 2);

        #5000;

        input_data = "C";
        #100; send(input_data);
        // #10; rx_done = 1;
        // #10; rx_done = 0;

        #(BIT_PERIOD / 2);
        force tb_command_controller_unit.dut.U_COUNTER_CONTROLLER_UNIT.btn_enable = 1;
        #10;
        release tb_command_controller_unit.dut.U_COUNTER_CONTROLLER_UNIT.btn_enable;
        #(BIT_PERIOD / 2);

        input_data = "M";
        #100; send(input_data);
        // #10; rx_done = 1;
        // #10; rx_done = 0;

        input_data = "c";
        #100; send(input_data);
        // #10; rx_done = 1;
        // #10; rx_done = 0;

        #(BIT_PERIOD / 2);
        force tb_command_controller_unit.dut.U_COUNTER_CONTROLLER_UNIT.btn_mode = 1;
        #10;
        release tb_command_controller_unit.dut.U_COUNTER_CONTROLLER_UNIT.btn_mode;
        #(BIT_PERIOD / 2);

        input_data = "r";
        #100; send(input_data);
        // #10; rx_done = 1;
        // #10; rx_done = 0;

        input_data = "m";
        #100; send(input_data);
        // #10; rx_done = 1;
        // #10; rx_done = 0;

        input_data = "a";
        #100; send(input_data);
        // #10; rx_done = 1;
        // #10; rx_done = 0;

        #100;
        $stop;
    end

// Test vector generation and send to UART
    task send(input [7:0] input_data);
    integer bit_cnt;
    begin 
        // expected_data = input_data;
        #10;

        rx = 0;
        #(BIT_PERIOD);
        for (bit_cnt = 0; bit_cnt < 8; bit_cnt = bit_cnt + 1) begin
            rx = input_data[bit_cnt];
            #(BIT_PERIOD);
        end

        // stop bit
        rx = 1;
        #(BIT_PERIOD);
        #10000;
    end
    endtask


endmodule
