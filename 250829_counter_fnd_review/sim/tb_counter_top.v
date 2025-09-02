`timescale 1ns / 1ps
module tb_counter_top();
    parameter MS = 1000000; // 1ms = 1,000,000ns
    reg clk, rst;
    reg mode; // 0: up, 1: down
    reg enable, clear;
    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    integer i;

    counter_top uut (
        .clk (clk),
        .rst (rst),
        .mode (mode),
        .enable (enable),
        .clear (clear),
        .fnd_com (fnd_com),
        .fnd_data (fnd_data)
    );

    always #5 clk = ~clk;

    initial begin
        #0 clk=0; rst=1;
        clear=0; mode=0; enable=0;
        #10 rst=0;

        // count up
        enable=1; mode=0;
        #(500*MS)
        // clear
        clear=1;
        #100
        clear=0;
        #(500*MS)
        // count down
        mode=1;
        #(500*MS)
        // stop
        enable=0;
        for (i = 0; i / 10; i = i + 1) begin
            wait(uut.U_FND_CONTROLLER.w_clk_div);
            #(MS);
        end

        $finish;
    end

endmodule
