`timescale 1ns / 1ps
module tb_button_debounce_edge_detector();
    reg clk, rst, btn_in;
    wire btn_out;

    integer random_btn_in;
    integer i = 0;

    btn_debounce_edge_detector dut (
        .clk (clk),
        .rst (rst),
        .btn_in (btn_in),
        .btn_out (btn_out)
    );

    always #5 clk = ~clk;   // 100Mhz clk, 1khz

    initial begin
        #0; clk = 0; rst = 1; btn_in = 1;
        #10; rst = 0;
        // one click test
        #10; btn_in = 1;
        #100; btn_in = 0;

        // pattern test w/ random
        for (i = 0; i < 256; i = i + 1) begin
            random_btn_in = $random;  // 0, 1
            #10; btn_in = random_btn_in[1];
            #100; btn_in = ~random_btn_in[1];
        end
    end
endmodule
