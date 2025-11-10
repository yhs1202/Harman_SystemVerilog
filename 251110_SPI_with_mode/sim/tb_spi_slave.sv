`timescale 1ns/1ps
module tb_spi_slave ();
    // global signals
    logic clk;
    logic rst;

    // internal signals
    logic CPOL;
    logic CPHA;

    // SPI Master internal signals
    logic m_start;    // master start signal
    logic [7:0] m_tx_data;
    logic [7:0] m_rx_data;
    logic m_tx_ready;
    logic m_done;


    // SPI Slave internal signals
    logic [7:0] s_rx_data;
    logic s_rx_done;
    logic [7:0] s_tx_data;
    logic s_tx_start;
    logic s_tx_ready;

    // SPI signals
    logic SCLK;
    logic MOSI;
    logic MISO;
    logic SS_n; // Slave Select (active low)

    // Instantiate the SPI Slave
    spi_master dut_master (
        .*,
        .start(m_start),
        .tx_data(m_tx_data),
        .rx_data(m_rx_data),
        .tx_ready(m_tx_ready),
        .done(m_done)
    );
    spi_slave dut (
        .*,
        .rx_data(s_rx_data),
        .rx_done(s_rx_done),
        .tx_data(s_tx_data),
        .tx_start(s_tx_start),
        .tx_ready(s_tx_ready)
    );


    // Testbench stimulus
    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; SCLK = 0; SS_n = 1;
        #10; rst = 0;
    end


    task automatic spi_mode(bit cpol, bit cpha);
        CPOL = cpol;
        CPHA = cpha;
    endtask //automatic

    task automatic spi_write(byte data);
        @(posedge clk);
        SS_n = 0;
        wait(m_tx_ready);
        m_start = 1;
        m_tx_data = data;
        @(posedge clk);
        m_start = 0;
        wait(m_done);
        @(posedge clk);
        SS_n = 1;    
    endtask //automatic


    task automatic spi_slave_out(byte data);
        @(posedge clk);
        wait (s_tx_ready);
        s_tx_data = data;
        s_tx_start = 1;
        @(posedge clk);
        s_tx_start = 0;
        wait(s_tx_ready);
    endtask //automatic


/*
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
*/

    initial begin
        repeat(5) @(posedge clk);

        spi_mode(1'b0, 1'b0);
        
        fork
            spi_write(8'hf0);
            spi_slave_out(8'haa);
        join
        // spi_write(8'h0f);
        // spi_write(8'haa);
        // spi_write(8'h55);

        #20; $stop;
    end

    
endmodule