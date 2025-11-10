`timescale 1ns/1ps
module tb_spi_master ();

    // global signals
    logic clk;
    logic rst;

    // internal signals
    logic CPOL;
    logic CPHA;
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
        // .MOSI(MISO_loopback)
        .MISO(MISO_loopback)
    );

    // Testbench stimulus
    always #5 clk = ~clk; // 100MHz clock

    initial begin
        clk = 0; rst = 1;
        #10; rst = 0;
    end

    task automatic spi_write(bit cpol, bit cpha, byte data);
        CPOL = cpol;
        CPHA = cpha;
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

        spi_write(1'b0, 1'b0, 8'hf0);
        repeat(10) @(posedge clk);
        spi_write(1'b0, 1'b1, 8'h0f);
        repeat(10) @(posedge clk);
        spi_write(1'b1, 1'b0, 8'haa);
        repeat(10) @(posedge clk);
        spi_write(1'b1, 1'b1, 8'h55);
        repeat(10) @(posedge clk);

        #20; $stop;

    end
    
endmodule