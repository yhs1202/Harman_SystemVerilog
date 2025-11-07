`timescale 1ns/1ps
module tb_spi_slave ();
    // global signals
    logic clk;
    logic rst;

    // SPI signals
    logic SCLK;
    logic MOSI;
    logic MISO;
    logic SS_n; // Slave Select (active low)

    // internal signals
    logic [7:0] rx_data;
    logic rx_done;


    // Instantiate the SPI Slave
    spi_slave dut (.*);


    // Testbench stimulus
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; SCLK = 0; SS_n = 1;
        #10; rst = 0;
    end

    task automatic spi_read(byte data);
        SS_n = 0;
        @(posedge clk);
        SCLK = 0;
        // Drive MOSI with data bits
        for (int i = 7; i >= 0; i--) begin
            MOSI = data[i];
            // Generate SCLK pulse
            repeat(50) @(posedge clk);
            SCLK = 1;
            repeat(50) @(posedge clk);
            SCLK = 0;
        end
        SS_n = 1;
        
    endtask //automatic


    initial begin
        repeat(5) @(posedge clk);
        spi_read(8'hf0);
        spi_read(8'h0f);
        spi_read(8'haa);
        spi_read(8'h55);

        #20; $stop;
    end

    
endmodule