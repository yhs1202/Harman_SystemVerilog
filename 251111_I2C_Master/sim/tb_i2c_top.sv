`timescale 1ns/1ps

module tb_i2c_top ();
    logic clk;
    logic rst;

    // Master-side signals
    logic [6:0] addr;
    logic [7:0] tx_data;
    logic i2c_en;
    logic rw;
    logic data_valid;
    logic data_next;
    logic read_last;
    logic [7:0] rx_data;
    logic ready;


    // Slave-side signals
    logic start_detect, stop_detect;
    logic slave_rw_mode;
    logic [7:0] slave_rx_data;
    logic slave_rx_valid;

    logic [7:0] slave_tx_data;
    logic slave_tx_valid;

    // I2C bus (open-drain)
    tri sda;
    tri scl;

    pullup(sda);
    pullup(scl);

    i2c_master u_master (
        .*,
        .i2c_sda (sda),
        .i2c_scl (scl)
    );

    i2c_slave #(
        .SLAVE_ADDR (7'h50)
    ) u_slave (
        .*,
        .sda (sda),
        .scl (scl),

        .start_detect (start_detect),
        .stop_detect  (stop_detect),
        .rw_mode      (slave_rw_mode),
        .rx_data      (slave_rx_data),
        .rx_valid     (slave_rx_valid),

        .tx_data    (slave_tx_data),
        .tx_valid   (slave_tx_valid)
    );


    // Simple 4-Byte Slave Memory (for testbench)
    logic [7:0] SLV_MEM [0:3];

    initial begin
        SLV_MEM[0] = 8'h00;
        SLV_MEM[1] = 8'h11;
        SLV_MEM[2] = 8'h22;
        SLV_MEM[3] = 8'h33;
    end

    // Slave logic: consume write data
    always_ff @(posedge clk) begin
        if (slave_rx_valid) begin
            SLV_MEM[0] <= slave_rx_data;  // slave write check
        end
    end

    // Slave logic: supply read data
    always_ff @(posedge clk) begin
        if (slave_rw_mode == 1) begin // master read operation
            slave_tx_data  <= SLV_MEM[0];  // slave read check
            slave_tx_valid <= 1;
        end else begin
            slave_tx_valid <= 0;
        end
    end


    always #5 clk = ~clk;
    initial begin
        #0; clk = 0; rst = 1;
        tx_data     = 8'h00;
        data_valid  = 0;
        read_last   = 0;
        rw          = 0;
        i2c_en      = 0;
        #10;
        rst = 0;
        addr        = 7'h50;

        wait(ready);
        @(posedge clk);

        // Write data to slave
        rw = 0; i2c_en = 1; tx_data = 8'h42; data_valid = 1;
        repeat(12) @(posedge clk);
        i2c_en = 0;

        wait(ready);    // wait for write completion

        // Read back the data
        rw = 1; i2c_en = 1; read_last = 1;
        repeat(12) @(posedge clk);
        i2c_en = 0;

        wait(data_next);
        @(posedge clk);
        wait(ready);    // wait for rx_data valid

        #100;
        $finish;
    end

endmodule
