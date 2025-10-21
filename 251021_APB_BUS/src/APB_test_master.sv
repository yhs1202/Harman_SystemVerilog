`timescale 1ns/1ps
module APB_test_master (
    // Global Signals
    input logic PCLK,
    input logic PRESET,

    // APB Interface Signals
    input logic [31:0] rdata,
    input logic ready,
    output logic transfer,
    output logic write,
    output logic [31:0] addr,
    output logic [31:0] wdata
);
    initial begin
        transfer = 1'b0; write = 1'b0; addr = 32'b0; wdata = 32'b0;
        wait(!PRESET);
        @(posedge PCLK);
        repeat (5) @(posedge PCLK);

        // Example write operation (100 stimulus)
        for (int i = 0; i < 100; i++) begin

            @(posedge PCLK);
            transfer = 1'b1;    // IDLE -> SETUP --> ACCESS (PENABLE = 1)
            addr = 32'h1000_0000 + $urandom_range(14'h3FFF, 14'h0000);  // PSELx = 1
            wdata = $urandom;
            $display("0x%0h", addr);
            @(posedge ready);   // PSEL && PENABLE
            write = 1'b1;
            transfer = 1'b0;
            @(negedge ready);



            repeat (5) @(posedge PCLK);
            #10;
        end

        // Finish simulation
        #10000;
        $finish;
    end


endmodule