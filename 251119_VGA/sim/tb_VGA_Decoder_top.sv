`timescale 1ns/1ps
module tb_VGA_Decoder_top;

    // Testbench signals
    logic clk;
    logic reset;
    logic h_sync;
    logic v_sync;

    // Instantiate the DUT
    VGA_Decoder_top dut (
        .clk(clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1;
        #20;
        reset = 0;
        @(negedge v_sync); // Wait for a vertical sync pulse

        // Finish simulation
        $finish;
    end

    initial begin
        $monitor("Time: %0t | h_sync: %b | v_sync: %b", $time, h_sync, v_sync);
    end
endmodule