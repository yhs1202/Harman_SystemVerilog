`timescale 1ns/1ps
module spi_slave_top (
    // global signals
    input logic clk,
    input logic rst,

    // SPI signals
    input logic SCLK,
    input logic MOSI,
    output logic MISO,  // not used
    input logic SS_n,

    // internal signals
    // output logic [7:0] rx_data,
    // output logic rx_done,

    // fnd outputs
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    logic [7:0] rx_data;
    logic rx_done;
    logic [15:0] disp_data;

    // Instantiate SPI Slave
    spi_slave u_spi_slave (.*);
    // Instantiate byte pair assembler
    byte_pair_assembler u_byte_pair_assembler (
        .*,
        .concatenated_data (disp_data)
    );
    // Instantiate fnd driver
    fnd_controller u_fnd_controller (
        .clk (clk),
        .rst (rst),
        .count_reg (disp_data[13:0]),
        .fnd_com (fnd_com),
        .fnd_data (fnd_data)
    );

    
endmodule



// Concatenate each two received bytes into a 16-bit word
module byte_pair_assembler (
    input logic clk,
    input logic rst,
    input logic [7:0] rx_data,
    input logic rx_done,    // valid
    output logic [15:0] concatenated_data
);
    logic [7:0] lsb8, msb8;
    logic toggle;

    enum logic {LSB, MSB} state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            lsb8 <= 8'b0;
            msb8 <= 8'b0;
            toggle <= MSB;
        end else if (rx_done) begin
            if (toggle == LSB) begin
                msb8 <= rx_data;
            end else begin
                lsb8 <= rx_data;
            end
            toggle <= ~toggle;
        end
    end

    assign concatenated_data = {msb8, lsb8};

endmodule