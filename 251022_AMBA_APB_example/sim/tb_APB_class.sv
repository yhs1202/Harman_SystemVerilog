`timescale 1ns/1ps

interface apb_master_if(
    input logic clk,    
    input logic reset
);
    logic transfer;
    logic write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic ready;
endinterface //apb_master_if


class apbSignal;
    logic transfer;
    logic write;
    rand logic [31:0] addr;
    rand logic [31:0] wdata;    // random data for write

    constraint addr_c {
        addr inside {
            [32'h1000_0000:32'h1000_0FFF],
            [32'h1000_1000:32'h1000_1FFF],
            [32'h1000_2000:32'h1000_2FFF],
            [32'h1000_3000:32'h1000_3FFF]
        };

        // 4-byte aligned
        addr % 4 == 0;
    }

    virtual apb_master_if m_if;

    function new(virtual apb_master_if m_if);
        this.m_if = m_if;
        
    endfunction //new()


    task automatic send();
        m_if.transfer <= 1'b1;
        m_if.write <= 1'b1; // write
        m_if.addr <= addr;
        m_if.wdata <= wdata;

        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;

        @(posedge m_if.clk);
        wait (m_if.ready);
        @(posedge m_if.clk);
    endtask //automatic


    task automatic receive();
        m_if.transfer <= 1'b1;
        m_if.write <= 1'b0; // read
        m_if.addr <= addr;

        @(posedge m_if.clk);
        m_if.transfer <= 1'b0;

        @(posedge m_if.clk);
        wait (m_if.ready);
        @(posedge m_if.clk);
    endtask //automatic

    
endclass //apbSignal

module tb_APB ();
    // Global Signals
    logic PCLK;
    logic PRESET;

    // APB Interface Signals
    logic [3:0] PADDR;
    logic PWRITE;
    logic PENABLE;
    logic [31:0] PWDATA;

    // Slave Select Signals
    logic PSEL0;
    logic PSEL1;
    logic PSEL2;
    logic PSEL3;
    logic [31:0] PRDATA0;
    logic [31:0] PRDATA1;
    logic [31:0] PRDATA2;
    logic [31:0] PRDATA3;
    logic PREADY0;
    logic PREADY1;
    logic PREADY2;
    logic PREADY3;

    /* Internal Interface Signals, Substituted by apb_master_if
    logic transfer;
    logic write;
    logic [31:0] addr;
    logic [31:0] wdata;
    logic [31:0] rdata;
    logic ready;
    */
    apb_master_if m_if(
        .clk    (PCLK),
        .reset  (PRESET)
    );

    // Instantiate APB Signal Handlers -> Stack Segment
    /*
    apbSignal apbUART;  // handler
    apbSignal apbUART_clone; // shallow copy
    apbSignal apbGPIO;  // handler
    apbSignal apbTIMER;  // handler
    */

    // apb instance
    apbSignal apbInst;


    APB_Manager dut_manager (
        .*,
        .transfer   (m_if.transfer),
        .write      (m_if.write),
        .addr       (m_if.addr),
        .wdata      (m_if.wdata),
        .rdata      (m_if.rdata),
        .ready      (m_if.ready)
    );

    APB_slave dut_slave_0 (
        .*,
        .PSEL   (PSEL0),
        .PRDATA (PRDATA0),
        .PREADY (PREADY0)
    );

    APB_slave dut_slave_1 (
        .*,
        .PSEL   (PSEL1),
        .PRDATA (PRDATA1),
        .PREADY (PREADY1)
    );

    APB_slave dut_slave_2 (
        .*,
        .PSEL   (PSEL2),
        .PRDATA (PRDATA2),
        .PREADY (PREADY2)
    );

    APB_slave dut_slave_3 (
        .*,
        .PSEL   (PSEL3),
        .PRDATA (PRDATA3),
        .PREADY (PREADY3)
    );

    always #5 PCLK = ~PCLK;

    initial begin
        #0  PCLK = 0;
            PRESET = 1;
        #10 PRESET = 0;
    end



    initial begin
        /*
        // new() -> heap allocation
        // create apbSignal objects
        apbUART = new(m_if);
        apbUART_clone = apbUART; // shallow copy
        apbGPIO = new(m_if);
        apbTIMER = new(m_if);

        repeat (3) @(posedge PCLK);

        apbUART.randomize();
        apbUART.send(32'h1000_0000);
        apbUART.read(32'h1000_0000);
        apbUART_clone.receive(32'h1000_0000);

        apbGPIO.randomize();
        apbGPIO.send(32'h1000_1000);
        apbGPIO.read(32'h1000_1000);
        apbGPIO.receive(32'h1000_1000);

        apbTIMER.randomize();
        apbTIMER.send(32'h1000_2000);
        apbTIMER.read(32'h1000_2000);
        apbTIMER.receive(32'h1000_2000);
        */

        // single apbSignal instance (HW)
        apbInst = new(m_if);
        wait (!PRESET);
        repeat (3) @(posedge PCLK);

        repeat (50) begin
            // 1. randomize signals
            apbInst.randomize();

            // 2. write (send)
            apbInst.send();

            // 3. read (receive)
            apbInst.receive();
            repeat (3) @(posedge PCLK);
        end

        $stop;
    end
endmodule