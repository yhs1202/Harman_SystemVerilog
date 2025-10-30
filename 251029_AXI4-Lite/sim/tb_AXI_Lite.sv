`timescale 1ns/1ps
module tb_AXI_LITE ();
    // Global signals
    logic ACLK;
    logic ARESETn;

    // Internal Signals
    logic transfer;
    logic ready;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic write;
    logic [31:0] rdata;

    top_AXI_Lite dut (.*);


    always #5 ACLK = ~ACLK;

    task automatic write_(input logic [31:0] address, input logic [31:0] data);
        @(negedge ACLK);
        transfer = 1'b1;
        write = 1'b1;
        addr = address;
        @(negedge ACLK);
        wdata = data;

        wait (ready);
        @(negedge ACLK);
        transfer = 1'b0;
        write = 1'b0;
    endtask //automatic

    task automatic read(input logic [31:0] address);
        @(negedge ACLK);
        write = 1'b0;
        transfer = 1'b1;
        addr = address;

        wait (ready);
        @(negedge ACLK);
        transfer = 1'b0;
    endtask //automatic

    initial begin
        #00;
        ACLK = 1'b0;
        ARESETn = 1'b0; // Active Low Reset

        #20;
        ARESETn = 1'b1;

        // Write Transactions
        write_(32'h0000_0000, 32'hDEED_BEEF);
        write_(32'h0000_0004, 32'hDEED_BEE0);
        write_(32'h0000_0008, 32'hDEED_BEE1);
        write_(32'h0000_000c, 32'hDEED_BEE2);
        // Read Transactions
        read(32'h0000_0000);
        read(32'h0000_0004);
        read(32'h0000_0008);
        read(32'h0000_000c);

        // Finish simulation
        #50;
        $finish;
    end
    
endmodule