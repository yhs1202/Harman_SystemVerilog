`timescale 1ns / 1ps

module tb_myip_axi_uart_gpio();



    // Parameters
    parameter C_S00_AXI_DATA_WIDTH = 32;
    parameter C_S00_AXI_ADDR_WIDTH = 32;

    // AXI-Lite Interface
    logic                               s00_axi_aclk;
    logic                               s00_axi_aresetn;
    logic [C_S00_AXI_ADDR_WIDTH-1:0]    s00_axi_awaddr;
    logic [2:0]                         s00_axi_awprot;
    logic                               s00_axi_awvalid;
    logic                               s00_axi_awready;
    logic [C_S00_AXI_DATA_WIDTH-1:0]    s00_axi_wdata;
    logic [(C_S00_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    logic                               s00_axi_wvalid;
    logic                               s00_axi_wready;
    logic [1:0]                         s00_axi_bresp;
    logic                               s00_axi_bvalid;
    logic                               s00_axi_bready;
    logic [C_S00_AXI_ADDR_WIDTH-1:0]    s00_axi_araddr;
    logic [2:0]                         s00_axi_arprot;
    logic                               s00_axi_arvalid;
    logic                               s00_axi_arready;
    logic [C_S00_AXI_DATA_WIDTH-1:0]    s00_axi_rdata;
    logic [1:0]                         s00_axi_rresp;
    logic                               s00_axi_rvalid;
    logic                               s00_axi_rready;


    // External ports
    wire [7:0]   gpio;
    logic         tx;
    logic         rx;

    // Clock generation
    initial s00_axi_aclk = 0;
    always #5 s00_axi_aclk = ~s00_axi_aclk; // 100MHz

    // DUT instance
    myip_v1_0 DUT (
        // AXI
        .*,

        // GPIO
        .gpio(gpio),

        // UART
        .tx(tx),
        .rx(rx)
    );

    // AXI write task
    task automatic axi_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge s00_axi_aclk);
        s00_axi_awaddr  <= addr;
        s00_axi_wdata   <= data;
        s00_axi_wstrb   <= 4'hF;    // 8-bit write
        s00_axi_awvalid <= 1;
        s00_axi_wvalid  <= 1;
        wait (s00_axi_awready);
        wait (s00_axi_wready);
        @(posedge s00_axi_aclk);
        s00_axi_awvalid <= 0;
        s00_axi_wvalid  <= 0;
        s00_axi_bready  <= 1;
        wait (s00_axi_bvalid);
        @(posedge s00_axi_aclk);
        s00_axi_bready  <= 0;
    end
    endtask

    // AXI read task
    task automatic axi_read(input [31:0] addr, output [31:0] data);
    begin
        @(posedge s00_axi_aclk);
        s00_axi_araddr  <= addr;
        s00_axi_arvalid <= 1;
        wait (s00_axi_arready);
        @(posedge s00_axi_aclk);
        s00_axi_arvalid <= 0;
        s00_axi_rready  <= 1;
        wait (s00_axi_rvalid);
        data = s00_axi_rdata;
        @(posedge s00_axi_aclk);
        s00_axi_rready  <= 0;
    end
    endtask

    // Loopback UART RX = TX for test
    assign rx = tx;
    logic [31:0] rdata;

    // Simulation procedure
    initial begin
        // Default init
        s00_axi_aclk    = 0;
        s00_axi_aresetn = 0;
        s00_axi_awvalid = 0;
        s00_axi_wvalid  = 0;
        s00_axi_arvalid = 0;
        s00_axi_bready  = 0;
        s00_axi_rready  = 0;
        repeat(10) @(posedge s00_axi_aclk);
        s00_axi_aresetn = 1;

        // GPIO test
        // UART test: write TX (0x10[5:2] -> 3'h4)
        axi_write(32'h10, 32'h0000_0041); // , write 'A'
        repeat(300000) @(posedge s00_axi_aclk); // wait for UART transfer

        // UART read RX (same address)
        // axi_read(32'h10, rdata);
        // $display("[%0t] UART RX Data = %h", $time, rdata[7:0]);

        // UART status (0x14[5:2] -> 3'h5)
        axi_read(32'h14, rdata);
        $display("[%0t] UART Status = %b", $time, rdata[3:0]);

        repeat(100) @(posedge s00_axi_aclk);
    end

endmodule
