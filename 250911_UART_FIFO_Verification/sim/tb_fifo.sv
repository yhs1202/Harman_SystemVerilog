`timescale 1ns / 1ps
// 1. Interface
interface fifo_if();
    logic clk;
    logic rst;
    logic w_en;
    logic r_en;
    logic [7:0] w_data;
    logic [7:0] r_data;
    logic full;
    logic empty;
endinterface

// 2. Transaction Class
class transaction;
    // for randomization
    rand bit w_en;
    rand bit r_en;
    rand bit [7:0] w_data;

    // for scoreboard comparison
    bit [7:0] r_data;
    bit full;
    bit empty;

    task display(string name);
        $display("[%t | %s]: w_en: %0b, r_en: %0b, w_data: %0h, r_data: %0h, full: %0b, empty: %0b", 
                 $time, name, w_en, r_en, w_data, r_data, full, empty);
    endtask // display

    constraint write_dist {
        // 80% chance to write
        w_en dist {0 := 2, 1 :=8};
    }
endclass

// 3. Generator Class
class generator;
    transaction tr;
    mailbox #(transaction) mbx_gen2drv;
    event gen_next_event;   // to synchronize generator and driver

    function new(mailbox #(transaction) mbx_gen2drv, event gen_next_event);
        this.mbx_gen2drv = mbx_gen2drv;
        this.gen_next_event = gen_next_event;
    endfunction // new()

    task run(int count);
        repeat (count) begin
            tr = new();
            assert (tr.randomize()) else begin
                $fatal("Failed to randomize");
            end
            mbx_gen2drv.put(tr);
            tr.display("GEN");
            @(gen_next_event); // wait for driver -> scoreboard to consume transaction
        end
    endtask // run
endclass


// 4. Driver Class
class driver;
    transaction tr;
    mailbox #(transaction) mbx_gen2drv;
    virtual fifo_if intf;
    event mon_next_event;   // to synchronize monitor and driver

    function new(mailbox #(transaction) mbx_gen2drv,
             virtual fifo_if intf,
             event mon_next_event);
        this.mbx_gen2drv = mbx_gen2drv;
        this.intf = intf;
        this.mon_next_event = mon_next_event;
    endfunction // new

    task reset();
        intf.clk = 0;
        intf.rst = 1;
        intf.w_en = 0;
        intf.r_en = 0;
        intf.w_data = 0;
        repeat (2) @(posedge intf.clk);
        intf.rst = 0;
        repeat (2) @(posedge intf.clk);
        $display("[%t] [DRV]: De-asserting reset", $time);
        // #1;
        // @(negedge intf.clk);
    endtask // reset

    task run();
        forever begin
            #1;
            mbx_gen2drv.get(tr);
            // drive signals to DUT
            intf.w_en = tr.w_en;
            intf.r_en = tr.r_en;
            intf.w_data = tr.w_data;
            // @(posedge intf.clk);
            // capture output signals from DUT
            // tr.r_data = intf.r_data;
            // tr.full = intf.full;
            // tr.empty = intf.empty;
            tr.display("DRV");
            #2;
            -> mon_next_event;
            @(posedge intf.clk);
            // notify monitor that transaction is consumed
        end
    endtask // run
endclass // driver


// 5. Monitor Class
class monitor;
    transaction tr;
    mailbox #(transaction) mbx_mon2scb;
    virtual fifo_if intf;
    event mon_next_event;

    function new(mailbox #(transaction) mbx_mon2scb,
                virtual fifo_if intf,
                event mon_next_event);
        this.mbx_mon2scb = mbx_mon2scb;
        this.intf = intf;
        this.mon_next_event = mon_next_event;
    endfunction // new

    task run();
        forever begin
            @(mon_next_event);
            tr = new();
            tr.w_en = intf.w_en;
            tr.r_en = intf.r_en;
            tr.w_data = intf.w_data;
            tr.r_data = intf.r_data;
            tr.full = intf.full;
            tr.empty = intf.empty;
            // send transaction to scoreboard
            // display transaction
            tr.display("MON");
            @(posedge intf.clk);
            mbx_mon2scb.put(tr);
        end
    endtask // run
endclass // monitor


// 6. Scoreboard Class
class scoreboard;
    transaction tr;
    mailbox #(transaction) mbx_mon2scb;
    event gen_next_event;   // to synchronize generator and scoreboard

    logic [7:0] fifo_queue[$:7];
    logic [7:0] expected_r_data;
    int passed_count = 0;
    int failed_count = 0;

    function new(mailbox #(transaction) mbx_mon2scb, event gen_next_event);
        this.mbx_mon2scb = mbx_mon2scb;
        this.gen_next_event = gen_next_event;
    endfunction // new

    task run();
        forever begin
            mbx_mon2scb.get(tr);

            tr.display("SCB");
            $display("====================================================================");
            // check full and empty flags
            if (tr.w_en) begin
                if (!tr.full) begin
                    fifo_queue.push_back(tr.w_data);
                    $display("[SCB] Write: %0h to FIFO, size = %0d", tr.w_data, fifo_queue.size());
                end
            end else begin
                $display("[SCB] FIFO is full. Write ignored.");
            end
            if (tr.r_en) begin
                if (!tr.empty) begin
                    expected_r_data = fifo_queue.pop_front();   // fifo_queue[0]
                    if (tr.r_data === expected_r_data) begin    // === -> exact match including X and Z
                        $display("[PASS]: r_data = %0h as expected", tr.r_data);
                        passed_count++;
                    end else begin
                        $error("[FAIL] Scoreboard Error: Expected r_data = %0h, Got r_data = %0h", expected_r_data, tr.r_data);
                        failed_count++;
                    end
                end else begin
                    $display("[SCB] FIFO is empty. Read ignored.");
                end
            end
            $display("Scoreboard Summary: Passed = %0d, Failed = %0d", passed_count, failed_count);
            $display("====================================================================");
            $display("%p", fifo_queue);
            $display("====================================================================");

            -> gen_next_event; // notify generator that transaction is consumed
        end
    endtask // run
endclass // scoreboard

// 7. Environment Class
class environment;
    transaction tr;
    mailbox #(transaction) mbx_mon2scb;
    mailbox #(transaction) mbx_gen2drv;
    virtual fifo_if intf;
    event gen_next_event;
    event mon_next_event;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    
    function new(virtual fifo_if intf);
        this.intf = intf;
        mbx_gen2drv = new();
        mbx_mon2scb = new();
        gen = new(mbx_gen2drv, gen_next_event);
        drv = new(mbx_gen2drv, intf, mon_next_event);
        mon = new(mbx_mon2scb, intf, mon_next_event);
        scb = new(mbx_mon2scb, gen_next_event);
    endfunction // new()

    task reset();
        drv.reset();
        // #1;
    endtask // reset

    task run();
        fork
            gen.run(100); // generate transactions
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $stop;
    endtask // run
endclass // environment

// 8. Test Class
module tb_fifo();
    fifo_if intf();
    environment env;

    fifo_top dut (
        .clk(intf.clk),
        .rst(intf.rst),
        .w_en(intf.w_en),
        .r_en(intf.r_en),
        .w_data(intf.w_data),
        .r_data(intf.r_data),
        .full(intf.full),
        .empty(intf.empty)
    );

    always #5 intf.clk = ~intf.clk;

    initial begin
        env = new(intf);
        env.reset();
        env.run();
    end

endmodule
