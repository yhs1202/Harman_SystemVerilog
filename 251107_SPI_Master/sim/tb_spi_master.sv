`timescale 1ns/1ps
module tb_spi_master ();

    // global signals
    logic clk;
    logic rst;

    // internal signals
    logic start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic tx_ready;
    logic done;       // Indicates completion of SPI transaction (tx, rx both)

    // SPI signals
    logic SCLK;
    logic MOSI;
    logic MISO;

    // loop-back MISO
    logic MISO_loopback;

    // Instantiate the SPI Master
    spi_master dut (
        .*,
        // Connect MISO to loopback
        .MISO(MISO_loopback),
        .MOSI(MISO_loopback)
    );

    // Testbench stimulus
    always #5 clk = ~clk; // 100MHz clock

    initial begin
        clk = 0; rst = 1;
        #10; rst = 0;
    end

    task automatic spi_write(byte data);
        @(posedge clk);
        wait(tx_ready);
        start = 1;
        tx_data = data;
        @(posedge clk);
        start = 0;
        wait(done);
        @(posedge clk);
    endtask //automatic

    initial begin
        repeat(5) @(posedge clk);
        spi_write(8'hf0);
        spi_write(8'h0f);
        spi_write(8'haa);
        spi_write(8'h55);

        #20; $stop;

    end
    
endmodule