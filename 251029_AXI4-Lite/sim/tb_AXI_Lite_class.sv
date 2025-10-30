`timescale 1ns/1ps

interface host_if(
    input logic clk,
    input logic reset
);
    // AXI4-Lite Internal Signals
    logic transfer;
    logic ready;
    logic [3:0] addr;
    logic [31:0] wdata;
    logic write;
    logic [31:0] rdata;
endinterface //host_if

class transaction;
    logic transfer;
    logic ready;
    randc logic [3:0] addr;
    rand logic [31:0] wdata;
    // logic write;
    logic [31:0] rdata;

    constraint c_addr {
        addr inside {[4'h0:4'hC]};
        addr % 4 == 0;
    }

    function void print(string name);
        $display("[%s] addr = %h, wdata = %h, rdata = %h", name, addr, wdata, rdata);
    endfunction //new()

endclass //Transaction

class tester;
    virtual host_if h_if;

    // Substituted with transaction class
    // logic transfer;
    // logic ready;
    // rand logic [3:0] addr;
    // rand logic [31:0] wdata;
    // logic write;
    // logic [31:0] rdata;

    // constraint c_addr {
    //     addr inside {[4'h0:4'hC]};
    //     addr % 4 == 0;
    // }

    transaction tr;

    function new(virtual host_if h_if);
        this.h_if = h_if;
        this.tr = new();
    endfunction //new()

    task automatic write();
        @(posedge h_if.clk);
        h_if.addr = tr.addr;
        h_if.wdata = tr.wdata;
        h_if.write = 1'b1;
        h_if.transfer = 1'b1;
        @(posedge h_if.clk);
        h_if.transfer = 1'b0;
        tr.print("WRITE");
        @(posedge h_if.clk);
        wait (h_if.ready);
        @(posedge h_if.clk);
    endtask //automatic

    task automatic read();
        @(posedge h_if.clk);
        h_if.addr = tr.addr;
        h_if.write = 1'b0;
        h_if.transfer = 1'b1;
        @(posedge h_if.clk);
        h_if.transfer = 1'b0;
        @(posedge h_if.clk);
        wait (h_if.ready);
        @(posedge h_if.clk);
        tr.rdata = h_if.rdata;
        tr.print("READ");
    endtask //automatic

    task automatic run(int loop);
        repeat (loop) begin
            assert(tr.randomize())
            else $fatal("Randomization failed");
            write();
            read();
        end
    endtask //automatic
endclass //tester

module tb_AXI_Lite_Master_Slave ();

    // Global signals
    logic ACLK;
    logic ARESETn;

    // AXI Write Address Channel
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
    
    host_if h_if (
        .clk    (ACLK),
        .reset  (ARESETn)
    );
    AXI_Lite_Master dut_Master (
        .*,
        .transfer   (h_if.transfer),
        .ready      (h_if.ready),
        .addr       (h_if.addr),
        .wdata      (h_if.wdata),
        .write      (h_if.write),
        .rdata      (h_if.rdata)
    );
    AXI_Lite_Slave dut_Slave (.*);

    tester axi_tester;

    always #5 ACLK = ~ACLK;

    initial begin
        #00
        axi_tester = new(h_if);
        ACLK = 1'b0;
        ARESETn = 1'b0; // Active Low Reset
        #10
        ARESETn = 1'b1; // Deassert Reset
    end

    initial begin
        repeat (5) @(posedge ACLK);
        /*
        // Write Transactions
        axi_tester.write(4'h00, 32'h1111_1111);
        axi_tester.write(4'h04, 32'h2222_2222);
        axi_tester.write(4'h08, 32'h3333_3333);
        axi_tester.write(4'h0C, 32'h4444_4444);

        // Read Transactions
        axi_tester.read(4'h00);
        axi_tester.read(4'h04);
        axi_tester.read(4'h08);
        axi_tester.read(4'h0C);
        */

        axi_tester.run(10);
    end
    
endmodule