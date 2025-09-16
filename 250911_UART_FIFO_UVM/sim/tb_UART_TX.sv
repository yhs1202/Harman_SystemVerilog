`timescale 1ns / 1ps
// 1. Interface
interface uart_tx_if();
    logic clk;
    logic rst;
    logic tx_start;
    logic [7:0] tx_data;
    logic tx_busy;
    logic tx;
    logic baud_tick;
endinterface //uart_tx_if


// 2. Transaction Class
class transaction;
    // for randomization (gen -> drv)
    rand bit [7:0] tx_data;

    // uart frame : start(0) + data(8) + stop(1) (gen->scb)
    bit start_bit;
    bit stop_bit;
    bit [7:0] uart_frame;

    task display(string name);
        $display("[%t|%10s] tx_data:%h (%b), frame:{%b %h %b}",
         $time, name, tx_data, tx_data, start_bit, uart_frame, stop_bit);
    endtask // display

endclass


// 3. Generator Class
class generator;
    transaction tr;
    mailbox #(transaction) mbx_gen2drv;
    mailbox #(transaction) mbx_gen2scb;
    event gen_next_event;   // to synchronize generator and driver

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
            tr = new();
            assert (tr.randomize()) else begin
                $fatal("Failed to randomize");
            end
            tr.start_bit = 0;
            tr.uart_frame = tr.tx_data;
            tr.tx_data = tr.tx_data; // for display purpose
            tr.stop_bit = 1;
            // send to driver
            mbx_gen2drv.put(tr);

            // also send to scoreboard with uart frame format
            mbx_gen2scb.put(tr);

            tr.display("GEN->DRV");
            tr.display("GEN->SCB");
            gen_count++;
            @(gen_next_event); // wait for driver -> scoreboard to consume transaction
        end
    endtask // run
endclass //generator


// 4. Driver Class
class driver;
    transaction tr;
    mailbox #(transaction) mbx_gen2drv;
    virtual uart_tx_if intf;

    // event mon_next_event;    // we don't need this event because monitor can be driven by negedge of tx (start bit).

    int drv_count = 0;

    function new(mailbox #(transaction) mbx_gen2drv,
                virtual uart_tx_if intf);
        this.mbx_gen2drv = mbx_gen2drv;
        this.intf = intf;
        // this.mon_next_event = mon_next_event;
    endfunction // new()

    task reset();
        // intf.clk = 0;    // not good to initialize clk here
        intf.rst = 1;
        intf.tx_start = 0;
        intf.tx_data = 0;
        repeat (2) @(posedge intf.clk);
        intf.rst = 0;
        repeat (2) @(posedge intf.clk);
    endtask // reset()


    task run();
        forever begin
            mbx_gen2drv.get(tr);
            drv_count++;
            // drive signals
            // if tx is busy, wait
            if (intf.tx_busy) begin
                // wait (!intf.tx_busy);
                @(negedge intf.tx_busy);
            end
            // assert signals
            repeat (5) @(posedge intf.clk);
            intf.tx_start = 1;
            intf.tx_data = tr.tx_data;
            
            // de-assert signals
            repeat (5) @(posedge intf.clk);
            intf.tx_start = 0;
            tr.display("DRV");
            // -> mon_next_event; // notify monitor that transaction is consumed
        end
    endtask // run()
endclass // driver


// 5. Monitor Class
// sample at middle of each bit period
class monitor;
    transaction tr;
    mailbox #(transaction) mbx_mon2scb;
    virtual uart_tx_if intf;
    // event mon_next_event;

    int mon_count = 0;

    function new(mailbox #(transaction) mbx_mon2scb,
                virtual uart_tx_if intf);
        this.mbx_mon2scb = mbx_mon2scb;
        this.intf = intf;
    endfunction // new()

    task run();
        forever begin
            // wait for driver to notify
            // @(mon_next_event); 
            

            // start bit
            tr = new();
            @(posedge intf.tx_busy);  // middle of start bit
            tr.start_bit = intf.tx; // should be 0

            repeat(16) @(posedge intf.baud_tick);
            // sampling
            for (int i = 0; i < 8; i++) begin
                repeat(8) @(posedge intf.baud_tick);
                tr.uart_frame[i] = intf.tx;
                repeat(8) @(posedge intf.baud_tick);
            end

            // stop bit
            repeat(8) @(posedge intf.baud_tick);
            tr.stop_bit = intf.tx; // should be 1
            tr.tx_data = tr.uart_frame; // for display purpose
            @(negedge intf.tx_busy);

            // display transaction information
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
            mbx_gen2scb.get(tr_expect);    // expected data from generator
            mbx_mon2scb.get(tr_actual);    // actual data from monitor
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
    mailbox #(transaction) mbx_mon2scb; // mon -> scb (actual data)
    mailbox #(transaction) mbx_gen2scb; // gen -> scb (expected data)
    virtual uart_tx_if intf;
    
    event gen_next_event;   // to synchronize generator and scoreboard
    // event mon_next_event;   // to synchronize driver and monitor
    
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    function new(virtual uart_tx_if intf);
        this.intf = intf;
        mbx_gen2drv = new();
        mbx_mon2scb = new();
        mbx_gen2scb = new();
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


// 8. Main Testbench
module tb_UART_TX();
    uart_tx_if intf();
    environment env;

    UART_top dut (
        // rx -> will not connect at this time
        .clk(intf.clk),
        .rst(intf.rst),
        .tx_start(intf.tx_start),
        .tx_data(intf.tx_data),
        .rx(1'b1), // idle state (rx tie-off)

        .tx_busy(intf.tx_busy),
        .tx(intf.tx),
        // .rx_data(),
        // .rx_done()
        .baud_tick(intf.baud_tick)
    );

    always #5 intf.clk = ~intf.clk;

    initial begin
        intf.clk = 0;
        env = new(intf);
        env.run(50);
    end
    
endmodule
