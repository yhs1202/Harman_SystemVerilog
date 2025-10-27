`timescale 1ns / 1ps

module tb_UART_CORE();

    // === Parameters ===
    localparam CLK_FREQ = 100_000_000;
    localparam BAUD     = 9600;
    localparam real BIT_PERIOD = 1_000_000_000.0 / BAUD;  // ns per bit

    // === DUT I/O ===
    logic clk, rst;
    logic [7:0] tx_data;
    logic tx_wr;
    logic tx_empty, tx_busy, TX;
    logic [7:0] rx_data;
    logic rx_rd;
    logic rx_valid;
    logic RX;

    // === Instantiate DUT ===
    UART_CORE #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) DUT (
        .clk(clk),
        .rst(rst),
        .tx_data(tx_data),
        .tx_wr(tx_wr),
        .tx_empty(tx_empty),
        .tx_busy(tx_busy),
        .TX(TX),
        .rx_data(rx_data),
        .rx_rd(rx_rd),
        .rx_valid(rx_valid),
        .RX(RX)
    );

    // === Clock Generation (100 MHz) ===
    initial clk = 0;
    always #5 clk = ~clk;   // 10ns period → 100MHz

    // === Reset ===
    initial begin
        rst = 1;
        RX  = 1;   // idle high
        tx_data = 8'h00;
        tx_wr   = 0;
        rx_rd   = 0;
        #100;
        rst = 0;
    end

    // === TX Test Procedure ===
    initial begin : TX_TEST
        wait(!rst);
        #1000;
        $display("\n=== UART TX TEST START ===");

        // transmit 3 bytes : 'A', 'B', 'C'
        repeat (3) begin
            send_byte();
            #2ms;
        end

        $display("=== UART TX TEST END ===\n");
    end

    task send_byte();
        automatic byte ch;
        begin
            ch = "A" + $urandom_range(0,2);  // random between 'A','B','C'
            tx_data = ch;
            tx_wr   = 1;
            @(posedge clk);
            tx_wr   = 0;
            $display("[%0t ns] TX WRITE: %c (0x%02h)", $time, ch, ch);
        end
    endtask

    // === RX Loopback ===
    // Connect TX → RX with optional delay to simulate wire
    always @(TX) RX <= TX;

    // === RX Monitor ===
    always @(posedge clk) begin
        if (rx_valid) begin
            $display("[%0t ns] RX VALID: %c (0x%02h)", $time, rx_data, rx_data);
            rx_rd <= 1;
        end else begin
            rx_rd <= 0;
        end
    end

    // === Simulation Timeout ===
    initial begin
        #100_000_000; // 100 ms sim limit
        $display("\nSimulation Timeout. Stopping.\n");
        $finish;
    end

endmodule
