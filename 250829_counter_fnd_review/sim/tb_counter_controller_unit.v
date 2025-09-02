`timescale 1ns / 1ps
module tb_counter_controller_unit();
    reg clk, rst;
    reg btn_enable, btn_clear, btn_mode;

    wire enable, clear, mode;

    counter_controller_unit U_COUNTER_CONTROLLER_UNIT (
        .clk (clk),
        .rst (rst),
        .btn_enable (btn_enable),
        .btn_clear (btn_clear),
        .btn_mode (btn_mode),

        .enable (enable),
        .clear (clear),
        .mode (mode)
    );

    always #5 clk = ~clk;

    initial begin
        #0 clk = 0; rst = 1; btn_enable = 0; btn_clear = 0; btn_mode = 0;
        #15 rst = 0;
        
        #20 btn_enable = 1;
        #40 btn_enable = 0;

        #50 btn_mode = 1;
        #40 btn_mode = 0;

        #50 btn_enable = 1;
        #40 btn_enable = 0;

        #50 btn_clear = 1;
        #40 btn_clear = 0;

        #50 btn_mode = 1;
        #40 btn_mode = 0;

        #50 btn_enable = 1;
        #40 btn_enable = 0;

        #50 $finish;
    end
endmodule
