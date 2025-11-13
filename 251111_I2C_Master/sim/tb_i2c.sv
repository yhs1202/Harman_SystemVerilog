`timescale 1ns / 1ps

// Testbench for I2C Controller
// Author: Hoseung Yoon
// Description:
// This testbench verifies the I2C controller by performing -
// multi-byte write and read transactions using a simple behavioral I2C slave model.

module tb_i2c_controller();

    // global signals
    logic clk;
    logic rst;

    // I2C transaction signals
    logic [6:0] addr;
    logic [7:0] tx_data;
    logic i2c_en;
    logic rw;

    // for multi-byte transactions
    logic data_valid;
    logic data_next;
    logic read_last;

    logic [7:0] rx_data;
    logic ready;

    tri i2c_sda;
    tri i2c_scl;

    // Open-drain pullups
    pullup(i2c_sda);
    pullup(i2c_scl);

    i2c_master dut (.*);

    // Simple I2C Slave Model (Functional Emulation)
    logic [7:0] memory [4];   // Memory buffer for read/write
    logic [2:0] bit_cnt;
    logic [7:0] recv_byte;
    logic [7:0] send_byte;
    logic [1:0] byte_idx;
    logic sda_drive;             // 1 = Drive SDA low
    logic scl_prev;

    assign i2c_sda = sda_drive ? 1'b0 : 1'bz;

    // Basic behavior:
    // - During address phase: slave drives ACK (SDA low)
    // - During write phase: slave samples SDA bits
    // - During read phase:  slave drives SDA with memory data
    // Sample data on SCL rising edge (I2C spec)
    always @(posedge i2c_scl or posedge rst) begin
        if (rst) begin
            bit_cnt <= 0;
            byte_idx <= 0;
            recv_byte <= 0;
            send_byte <= 0;
            sda_drive <= 0;
            memory[0] <= 8'hAA;
            memory[1] <= 8'hBB;
            memory[2] <= 8'hCC;
            memory[3] <= 8'hDD;
        end else begin
            // Only sample when master is writing (rw == 0)
            if (dut.state == dut.WRITE_DATA) begin
                recv_byte <= {recv_byte[6:0], i2c_sda};  // shift in MSB-first
                bit_cnt <= bit_cnt + 1;
                if (bit_cnt == 7) begin
                    memory[byte_idx] <= {recv_byte[6:0], i2c_sda}; // store full byte
                    byte_idx <= byte_idx + 1;
                    bit_cnt <= 0;
                end
            end
        end
    end

    // Drive SDA during read phase
    always @(negedge i2c_scl or posedge rst) begin
        if (rst) sda_drive <= 0;
        else begin
            case (dut.state)
            dut.READ_ACK:  sda_drive <= 1'b1;  // ACK for address
            dut.READ_ACK2: sda_drive <= 1'b1;  // ACK for write data
            dut.WRITE_ACK: sda_drive <= 1'b0;  // release during read
            default:       sda_drive <= 1'b0;
            endcase
        end
    end


    always #5 clk = ~clk;

    initial begin
        #0; clk = 0; rst = 1;
        i2c_en = 0;
        rw = 0;
        addr = 7'h50;    // Arbitrary slave address
        tx_data = 8'h00;
        data_valid = 0;
        read_last = 0;
        #100;
        rst = 0;

        // 1. Multi-byte WRITE sequence (00, 0F, F0, 55)
        wait(ready);
        @(posedge clk);
        rw = 0;          // Write mode
        i2c_en = 1;
        tx_data = 8'h00;
        data_valid = 1;
        repeat(12) @(posedge clk);
        i2c_en = 0;

        // Second byte
        wait(dut.data_next);
        @(posedge clk);
        tx_data = 8'h0F;
        data_valid = 1;
        repeat(12) @(posedge clk);
        i2c_en = 0;

        // Third byte
        wait(dut.data_next);
        @(posedge clk);
        tx_data = 8'hF0;
        data_valid = 1;
        repeat(12) @(posedge clk);
        i2c_en = 0;

        // Fourth byte
        wait(dut.data_next);
        @(posedge clk);
        tx_data = 8'h55;
        data_valid = 0; // Last byte
        i2c_en = 1;
        repeat(12) @(posedge clk);
        i2c_en = 0;

        wait(ready);
        $display("WRITE sequence finished at %t", $time);

        // 2. Multi-byte READ sequence (Expect: AA, BB, CC, DD)
        rw = 1;          // Read mode
        i2c_en = 1;
        read_last = 0;
        repeat(12) @(posedge clk);
        i2c_en = 0;

        repeat(4) begin : READ_LOOP
            wait(dut.data_next);
            repeat(12) @(posedge clk);
            $display("READ byte %0d = %02h", dut.byte_cnt, rx_data);
            // Mark last byte
            if (dut.byte_cnt == 3) begin
                wait(dut.data_next);
                read_last = 1;
            end
        end

        wait(ready);
        $display("READ sequence finished at %t", $time);

        #100;
        $finish;
    end

endmodule
