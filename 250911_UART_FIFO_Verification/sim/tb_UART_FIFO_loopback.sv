`timescale 1ns / 1ps
// 1. Interface
interface uart_fifo_if();
    logic clk;
    logic rst;
    logic rx;
    logic tx;
    logic baud_tick;
endinterface //uart_fifo_if


// 2. Transaction Class
class transaction;
    rand bit [7:0] rx_data;

    // uart frame : start(0) + data(8) + stop(1) (gen->scb)
    bit start_bit;
    bit stop_bit;
    bit [7:0] uart_frame;

    task display(string name);
        $display("[%t|%10s]: rx_data: %0h (%b), frame: {%b %b %b}", 
        $time, name, rx_data, rx_data, start_bit, uart_frame, stop_bit);
    endtask
endclass


// 3. Generator Class
class generator;
    transaction tr_to_drv, tr_to_scb;
    mailbox #(transaction) mbx_gen2drv;
    mailbox #(transaction) mbx_gen2scb;
    event gen_next_event;   // to synchronize generator and scoreboard

    int gen_count = 0;

    function new(mailbox #(transaction) mbx_gen2drv,
                mailbox #(transaction) mbx_gen2scb,
                event gen_next_event);
        this.mbx_gen2drv = mbx_gen2drv;
        this.mbx_gen2scb = mbx_gen2scb;
        this.gen_next_event = gen_next_event;
    endfunction //new()

    task run(int count);
        repeat (count) begin
            tr_to_drv = new();
            tr_to_scb = new();
            assert (tr_to_drv.randomize()) else begin
                $fatal("Failed to randomize");
            end
            // send to driver
            tr_to_drv.start_bit = 0;
            tr_to_drv.uart_frame = tr_to_drv.rx_data;
            tr_to_drv.stop_bit = 1;
            mbx_gen2drv.put(tr_to_drv);

            // also send to scoreboard with uart frame format 
            tr_to_scb.start_bit = 0;
            tr_to_scb.uart_frame = tr_to_drv.rx_data;
            tr_to_scb.rx_data = tr_to_drv.rx_data;  // for display purpose
            tr_to_scb.stop_bit = 1;
            mbx_gen2scb.put(tr_to_scb);

            tr_to_drv.display("GEN->DRV");
            tr_to_scb.display("GEN->SCB");
            gen_count++;
            @(gen_next_event); // wait for driver -> scoreboard to consume transaction
        end
    endtask // run
endclass //generator


// 4. Driver Class
class driver;
    transaction tr;
    mailbox #(transaction) mbx_gen2drv;
    virtual uart_fifo_if intf;
    
    // event mon_next_event;    // we don't need this event because monitor can be driven by negedge of tx (start bit).

    int drv_count = 0;

    function new(mailbox #(transaction) mbx_gen2drv, virtual uart_fifo_if intf);
        this.mbx_gen2drv = mbx_gen2drv;
        this.intf = intf;
        // this.mon_next_event = mon_next_event;
    endfunction

    task reset();
        intf.rst = 1;
        intf.rx = 1; // idle
        intf.tx = 1; // idle
        repeat(5) @(posedge intf.clk);
        intf.rst = 0;
        repeat(5) @(posedge intf.clk);
        $display("Reset done!");
    endtask

    task run();
        forever begin
            // get transaction from generator
            mbx_gen2drv.get(tr);
            drv_count++;
            tr.display("DRV");
            // drive the interface signals
            // start bit
            intf.rx = 0;
            @(posedge intf.clk);

            repeat(16) @(posedge intf.baud_tick);
            // data bits, LSB first
            for (int i=0; i<8; i++) begin
                repeat(8) @(posedge intf.baud_tick);
                intf.rx = tr.rx_data[i];
                repeat(8) @(posedge intf.baud_tick);
                // @(posedge intf.clk);
            end
            // stop bit
            repeat(8) @(posedge intf.baud_tick);
            intf.rx = 1;
            // @(posedge intf.clk);
        end
    endtask
endclass


// 5. Monitor Class
class monitor;
    transaction tr;
    mailbox #(transaction) mbx_mon2scb;
    virtual uart_fifo_if intf;
    // event mon_next_event;    // we don't need this event because monitor can be driven by negedge of tx (start bit).

    int mon_count = 0;

    function new(mailbox #(transaction) mbx_mon2scb,
                virtual uart_fifo_if intf);
        this.mbx_mon2scb = mbx_mon2scb;
        this.intf = intf;
        // this.mon_next_event = mon_next_event;
    endfunction // new()

    task run();
        forever begin
            // wait for driver to notify
            // @(mon_next_event); 
            
            // start bit
            tr = new();
            @(negedge intf.tx);
            tr.start_bit = intf.tx; // should be 0
            repeat(16) @(posedge intf.baud_tick);   // baud_tick is 16 times slower than clk

            // data bits sampling
            for (int i = 0; i < 8; i++) begin
                repeat(8) @(posedge intf.baud_tick);
                tr.uart_frame[i] = intf.tx;         // sample at the middle of each bit period
                repeat(8) @(posedge intf.baud_tick);
            end

            // stop bit
            repeat(8) @(posedge intf.baud_tick);
            tr.stop_bit = intf.tx; // should be 1
            tr.rx_data = tr.uart_frame; // for display purpose
            // @(negedge intf.tx_busy);

            // send to scoreboard and display
            mbx_mon2scb.put(tr);
            mon_count++;
            tr.display("MON");
        end
    endtask // run()
endclass // monitor

// 6. Scoreboard Class
class scoreboard;
    transaction tr_expect; // from generator
    transaction tr_actual; // from monitor

    mailbox #(transaction) mbx_mon2scb;
    mailbox #(transaction) mbx_gen2scb;
    event gen_next_event;

    bit [9:0] expected, actual;
    int passed_count = 0;
    int failed_count = 0;

    function new(mailbox #(transaction) mbx_mon2scb,
                mailbox #(transaction) mbx_gen2scb,
                event gen_next_event);
        this.mbx_mon2scb = mbx_mon2scb;
        this.mbx_gen2scb = mbx_gen2scb;
        this.gen_next_event = gen_next_event;
    endfunction // new()

    task run();
        forever begin
            // compare tr_expect and tr_actual
            mbx_gen2scb.get(tr_expect);
            mbx_mon2scb.get(tr_actual);
            $display("================================================");
            expected = {tr_expect.start_bit, tr_expect.uart_frame, tr_expect.stop_bit};
            actual = {tr_actual.start_bit, tr_actual.uart_frame, tr_actual.stop_bit};
            if (expected == actual) begin
                passed_count++;
                $display("Scoreboard: PASSED! frame = %b", actual);
            end
            else begin
                failed_count++;
                $display("Scoreboard: FAILED! expected = %b, actual = %b", expected, actual);
            end
            $display("================================================");
            -> gen_next_event; // notify generator that transaction is consumed
        end
    endtask // run()
endclass // scoreboard


// 7. Environment Class
class environment;
    transaction tr;
    mailbox #(transaction) mbx_gen2drv; // gen -> drv
    mailbox #(transaction) mbx_gen2scb; // gen -> scb (expected data)
    mailbox #(transaction) mbx_mon2scb; // mon -> scb (actual data)
    virtual uart_fifo_if intf;
    
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    event gen_next_event;
    // event mon_next_event;

    function new(virtual uart_fifo_if intf);
        this.intf = intf;
        mbx_gen2drv = new();
        mbx_gen2scb = new();
        mbx_mon2scb = new();
        gen = new(mbx_gen2drv, mbx_gen2scb, gen_next_event);
        drv = new(mbx_gen2drv, intf);
        mon = new(mbx_mon2scb, intf);
        scb = new(mbx_mon2scb, mbx_gen2scb, gen_next_event);
    endfunction // new()

    task report();
        // report the status of all components
        $display("################### Environment Report ###################");
        $display("Generator: Total transactions = %0d", gen.gen_count);
        $display("Driver: Total transactions = %0d", drv.drv_count);
        $display("Monitor: Total transactions = %0d", mon.mon_count);
        $display("Scoreboard: Passed = %0d, Failed = %0d", scb.passed_count, scb.failed_count);
        if (scb.failed_count == 0) begin
            $display("Overall Result: PASSED");
        end else begin
            $display("Overall Result: FAILED");
        end
        $display("#########################################################");
    endtask // report

    task run(int count);
        drv.reset();
        fork
            gen.run(count);
            drv.run();
            mon.run();
            scb.run();
        join_any
        report();
        #10;
        $stop;
    endtask // run
endclass // environment


// 8. Testbench Module
module tb_UART_FIFO_loopback();
    uart_fifo_if intf();
    environment env;

    // Instantiate the DUT
    UART_FIFO_loopback dut (
        .clk(intf.clk),
        .rst(intf.rst),
        .rx(intf.rx),
        .tx(intf.tx),
        .baud_tick(intf.baud_tick)
    );

    always #5 intf.clk = ~intf.clk;

    initial begin
        intf.clk = 0;
        env = new(intf);
        env.run(10);
        
    end

endmodule
