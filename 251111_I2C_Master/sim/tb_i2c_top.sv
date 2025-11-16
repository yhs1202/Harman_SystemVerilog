`timescale 1ns/1ps
module i2c_top_tb;
    // Global signals
    logic clk;
    logic rst;

    // Master-side signals
    logic [6:0] addr;
    logic [7:0] tx_data;
    logic i2c_en;
    logic rw;

    // Master-side output signals, to observe
    logic is_ack;
    logic is_nack;
    logic [7:0] rx_data;
    logic ready;

    // I2C bus (open-drain)
    tri sda;
    tri scl;

    // Pull-up resistors for I2C bus
    pullup(sda);
    pullup(scl);


    // Slave-side signals
    logic [7:0] slave_send_data;    // Master read
    logic [7:0] slave_recv_data;    // Master write
    logic slave_send_valid;
    logic slave_recv_valid;


    // Instantiation
    i2c_master u_master (.*);

    i2c_slave #(
        .SLAVE_ADDR (7'h50)
    ) u_slave (
        .*,
        .data_in (slave_recv_data),
        .data_out (slave_send_data),
        .send_valid (slave_send_valid)

    );

    always #5 clk = ~clk;

    // Simple 4-Byte Slave Memory (for testbench)
    logic [7:0] SLV_MEM [0:9];

    initial begin
        // SLV_MEM[0] = 8'h55;
        // SLV_MEM[1] = 8'hAA;
        SLV_MEM[0] = 8'h00;
        SLV_MEM[1] = 8'h11;
        SLV_MEM[2] = 8'h22;
        SLV_MEM[3] = 8'h33;
        SLV_MEM[4] = 8'h44;
        SLV_MEM[5] = 8'h55;
        SLV_MEM[6] = 8'h66;
        SLV_MEM[7] = 8'h77;
        SLV_MEM[8] = 8'h88;
        SLV_MEM[9] = 8'h99;
    end

    int idx;
    // Simple AXI interface logic for slave memory access
    always_ff @(posedge clk) begin
        if(!rw && slave_recv_valid) begin
            SLV_MEM[idx] <= slave_recv_data;
        end
        if (rw) begin // master read operation
            slave_send_data  <= SLV_MEM[idx];
            // slave_send_valid <= 1;
        // end else begin
            // slave_send_valid <= 0;
        end
    end

    

    initial begin
        clk = 0; rst = 1;
        slave_send_valid = 0; 
        slave_recv_valid = 0;
        repeat (5) @(posedge clk);
        rst = 0;
        idx = 0;

        for (int i = 0; i < 10; i++) begin
            i2c_en = 1; rw = 0;
            addr = 7'b1010000;
            tx_data = i+1;
            repeat (5) @(posedge clk);
            i2c_en <= 1'b0;
            slave_recv_valid = 0;
            
            @(posedge ready);
            idx = i;
            slave_recv_valid = 1;
            repeat (5) @(posedge clk);
        end
        slave_recv_valid = 0;
        idx = 0;
        repeat (100) @(posedge clk);


        for (int i = 0; i < 10; i++) begin
            i2c_en = 1; rw = 1;
            addr = 7'b1010000;
            slave_send_valid = 1;
            repeat (5) @(posedge clk);
            i2c_en <= 1'b0;
            @(posedge ready);
            slave_send_valid = 0;
            idx = i;
            @(posedge clk);
        end

        repeat (100) @(posedge clk);
        $stop;
    end

endmodule
