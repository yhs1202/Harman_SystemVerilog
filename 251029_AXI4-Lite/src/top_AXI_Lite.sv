`timescale 1ns/1ps
module top_AXI_Lite (
    // Global signals
    input logic ACLK,
    input logic ARESETn,
    // Internal Signals
    input logic transfer,
    output logic ready,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic write,
    output logic [31:0] rdata
);


    // AXI Signals
    logic [3:0] AWADDR;
    logic AWVALID;
    logic AWREADY;

    logic [31:0] WDATA;
    logic WVALID;
    logic WREADY;

    logic [1:0] BRESP;
    logic BVALID;
    logic BREADY;

    logic [3:0] ARADDR;
    logic ARVALID;
    logic ARREADY;

    logic [31:0] RDATA;
    logic RVALID;
    logic RREADY;
    logic [1:0] RRESP;

    // Instantiate
    AXI_Lite_Master U_MASTER (.*);
    AXI_Lite_Slave  U_SLAVE  (.*);
    
endmodule