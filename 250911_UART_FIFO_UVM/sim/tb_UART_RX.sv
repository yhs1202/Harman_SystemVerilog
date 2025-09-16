`timescale 1ns / 1ps
// 1. Interface
interface uart_rx_if;
    logic clk;
    logic rst;
    logic rx;
    logic [7:0] rx_data;
endinterface //uart_top_tx_interface


// 2. Transaction Class
class transaction;
    rand bit [7:0] rx_data;

    constraint data_c {
        rx_data inside { [1:254] };
    }

    task display(string name);
        $display("%t:[%s] : rx_data : %0h", $time, name, rx_data);
    endtask
endclass


// 3. Generator Class
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event gen_next_event;

    int gen_count = 0;

    function new(mailbox #(transaction) gen2drv_mbox, mailbox #(transaction) gen2scb_mbox, event gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_event = gen_next_event;
        this.gen2scb_mbox = gen2scb_mbox;
    endfunction

    task run(int count);
        repeat(count) begin
            gen_count++;
            tr = new;
            assert(tr.randomize()) else begin
                $fatal("Failed to randomize");
            end
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            tr.display("GEN");
            @(gen_next_event);
        end
    endtask

endclass


// 4. Driver Class
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_rx_if intf;
    event mon_next_event;

    int drv_count = 0;

    function new(mailbox #(transaction) gen2drv_mbox, virtual uart_rx_if intf, event mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.intf = intf;
        this.mon_next_event = mon_next_event;
    endfunction

    task reset();
        intf.rst = 1;
        intf.rx = 1'b1;
        repeat(5) @(posedge intf.clk);
        intf.rst = 0;
        repeat(5) @(posedge intf.clk);
        $display("Reset done!");
    endtask

    // 9600 baud with a 100MHz clock (10ns period)
    localparam BAUD_RATE_DIVISOR = 100_000_000 / 9600;

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            drv_count++;
            $display("%t:[Drv] Transmitting data: %0h", $time, tr.rx_data);
            
            @(posedge intf.clk);
            
            intf.rx = 1'b0;
            repeat(BAUD_RATE_DIVISOR) @(posedge intf.clk);

            for (int i = 0; i < 8; i++) begin
                intf.rx = tr.rx_data[i];
                repeat(BAUD_RATE_DIVISOR) @(posedge intf.clk);
            end

            intf.rx = 1'b1;
            repeat(BAUD_RATE_DIVISOR) @(posedge intf.clk);
            
            -> mon_next_event;
        end
    endtask
endclass


// 5. Monitor Class
class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual uart_rx_if intf;
    event mon_next_event;

    int mon_count = 0;
    
    function new(mailbox #(transaction) mon2scb_mbox, 
                virtual uart_rx_if intf,
                event mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.intf = intf;
        this.mon_next_event = mon_next_event;
    endfunction

    task run();
        forever begin
            @(mon_next_event);
            tr = new();
            tr.rx_data = intf.rx_data;
            
            mon_count++;
            tr.display("Mon"); 
            mon2scb_mbox.put(tr);
        end
    endtask
endclass


// 6. Scoreboard Class
class scoreboard;
    transaction tr_expect, tr_actual;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event gen_next_event;

    int pass_count, fail_count = 0;

    function new(mailbox #(transaction) mon2scb_mbox, mailbox #(transaction) gen2scb_mbox, event gen_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run();
        forever begin
            gen2scb_mbox.get(tr_expect);
            mon2scb_mbox.get(tr_actual);
            
            tr_expect.display("Scb-Exp");
            tr_actual.display("Scb-Act");
            
            if (tr_actual.rx_data == tr_expect.rx_data) begin
                $display("[SCB] PASS: Expect = %0x, Actual = %0x", tr_expect.rx_data, tr_actual.rx_data);
                pass_count++;
            end else begin
                $display("[SCB] FAIL: Expect = %0x, Actual = %0x", tr_expect.rx_data, tr_actual.rx_data);
                fail_count++;
            end
            -> gen_next_event;
        end
    endtask

endclass


// 7. Environment Class
class environment;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    virtual uart_rx_if intf;

    event gen_next_event;
    event mon_next_event;
    
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;

    function new(virtual uart_rx_if intf);
        this.intf = intf;
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen2scb_mbox = new();
        gen = new(gen2drv_mbox, gen2scb_mbox, gen_next_event);
        drv = new(gen2drv_mbox, intf, mon_next_event);
        mon = new(mon2scb_mbox, intf, mon_next_event);
        scb = new(mon2scb_mbox, gen2scb_mbox, gen_next_event);
    endfunction

    task report();
        // report the status of all components
        $display("################### Environment Report ###################");
        $display("Generator: Total transactions = %0d", gen.gen_count);
        $display("Driver: Total transactions = %0d", drv.drv_count);
        $display("Monitor: Total transactions = %0d", mon.mon_count);
        $display("Scoreboard: Passed = %0d, Failed = %0d", scb.pass_count, scb.fail_count);
        if (scb.fail_count == 0) begin
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
        $stop;
    endtask
endclass


// 8. Main Testbench Module
module tb_uart_top_rx();
    uart_rx_if intf();
    environment env;

    UART_top dut (
        // tx -> will not connect at this time
        .clk(intf.clk),
        .rst(intf.rst),
        // .tx_start(),
        // .tx_data(),
        .rx(intf.rx),

        // .tx_busy(),
        // .tx(),
        .rx_data(intf.rx_data)
        // .rx_done()
        // .baud_tick()
    );

    always #5 intf.clk = ~intf.clk;

    initial begin
        intf.clk = 0;
        env = new(intf);
        env.run(50);
    end

endmodule
