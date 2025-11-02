//////////////////////// TOP /////////////////////////////
`timescale 1 ns / 1 ps

	module myip_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 4
	)
	(
		// Users to add ports here

		// GPIO Port
		inout [7:0] gpio,


		// UART_FIFO Port
		input wire rx,
		output wire tx,

		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
	
		// GPIO Internal Signals
		wire [7:0] cr;
		wire [7:0] odr;
		wire [7:0] idr;

		// UART_FIFO Internal Signals
		wire tx_we;
		wire rx_re;

		wire rx_full;
		wire tx_empty;
		wire tx_full;
		wire rx_empty;

		wire [7:0] rx_data;
		wire [7:0] tx_data;

// Instantiation of Axi Bus Interface S00_AXI
	myip_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) myip_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		// internal signals
		// GPIO Interface
		.cr(cr),
		.odr(odr),
		.idr(idr),
		// UART_FIFO Interface
		.tx_we(tx_we),
		.rx_re(rx_re),

		.rx_full(rx_full),
		.tx_empty(tx_empty),
		.tx_full(tx_full),
		.rx_empty(rx_empty),

		.rx_data(rx_data),
		.tx_data(tx_data)
	);


	// Add user logic here
	GPIO U_GPIO (
		.cr(cr),
		.odr(odr),
		.idr(idr),
		.gpio(gpio)
	);


	// UART_FIFO
	UART_FIFO_CORE U_UART_FIFO_CORE (
		.clk(s00_axi_aclk),
		.rst(~s00_axi_aresetn),
		
		// Status Signals
		.rx_full(rx_full),
		.rx_empty(rx_empty),
		.tx_full(tx_full),
		.tx_empty(tx_empty),

		// RX Interface
		.rx(rx),
		.rx_data(rx_data),
		.rx_re(rx_re),

		// TX Interface
		.tx(tx),
		.tx_data(tx_data),
		.tx_we(tx_we)
	);

	// User logic ends

	endmodule

module GPIO (
	input [7:0] cr,
	input [7:0] odr,
	output [7:0] idr,
	inout [7:0] gpio
);
	genvar i;
	generate
		for (i = 0; i < 8; i = i + 1) begin
			assign gpio[i] = cr[i] ? odr[i] : 1'bz;
			assign idr[i] = ~cr[i] ? gpio[i] : 1'bz;
		end
	endgenerate
endmodule