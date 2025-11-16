// I2C Top module
// Author: Hoseung Yoon
// Description:



////////////////// when sda_en is high master will send data
///////////////// data is send only when scl is low
module i2c_top (
    input logic clk,
    input logic rst,

    input logic [6:0] addr,
    input logic [7:0] tx_data,
    input logic i2c_en,
    input logic rw,

    output logic is_ack,
    output logic is_nack,
    output logic [7:0] rx_data,
    output logic ready

);
    wire sda, scl;
    wire [7:0] data_tobe_master;
    wire [7:0] data_in;
    wire send_valid;


    i2c_master master (.*);
    i2c_slave slave (.*);



endmodule

