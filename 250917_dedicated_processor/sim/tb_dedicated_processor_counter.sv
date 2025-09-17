`timescale 1ns/1ps

module tb_dedicated_processor_counter;

    logic clk;
    logic rst;
    logic [7:0] out = 0;

    dedicated_processor_counter U_DPC (
        .clk(clk),
        .rst(rst),
        .out(out)
    );

    always #5 clk = ~clk;

    initial begin
        #0; clk = 0; rst = 0;
        #10; rst = 1;
        #10;    
        rst = 0;
        #1000 $stop;
    end

endmodule