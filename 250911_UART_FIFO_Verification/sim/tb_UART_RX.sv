`timescale 1ns / 1ps
interface uart_top_rx_interface;
    logic clk;
    logic rst;
    logic rx;
    logic [7:0] rx_data;
    logic rx_done;
endinterface //uart_top_tx_interface

class transaction;
    rand bit [7:0] rx_data;
    bit rx_done;

    constraint data_c {
        rx_data inside { [1:254] };
    }

    task display(string name);
        $display("%t:[%s] : rx_data : %0h, rx_done : %0b",
        $time, name, rx_data, rx_done);
    endtask
endclass

class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) gen2scb_mbox;
    event gen_next_event;

    int total_count = 0;

    function new(mailbox #(transaction) gen2drv_mbox, mailbox #(transaction) gen2scb_mbox, event gen_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen_next_event = gen_next_event;
        this.gen2scb_mbox = gen2scb_mbox;
    endfunction

    task run(int count);
        repeat(count) begin
            total_count++;
            tr = new;
            assert(tr.randomize())
            else $display("Random Error!!!!");
            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr);
            tr.display("[Gen]");
            @(gen_next_event);
        end
    endtask

endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual uart_top_rx_interface uart_top_rx_interface_if;
    event mon_next_event;

    function new(mailbox #(transaction) gen2drv_mbox, virtual uart_top_rx_interface uart_top_rx_interface_if, event mon_next_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.uart_top_rx_interface_if = uart_top_rx_interface_if;
        this.mon_next_event = mon_next_event;
    endfunction

    task reset();
        uart_top_rx_interface_if.rst = 1;
        uart_top_rx_interface_if.rx = 1'b1;
        repeat(5) @(posedge uart_top_rx_interface_if.clk);
        uart_top_rx_interface_if.rst = 0;
        repeat(5) @(posedge uart_top_rx_interface_if.clk);
        $display("Reset done!");
    endtask

    // 9600 baud with a 100MHz clock (10ns period)
    localparam BAUD_RATE_DIVISOR = 100_000_000 / 9600;

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            $display("%t:[Drv] Transmitting data: %0h", $time, tr.rx_data);
            
            @(posedge uart_top_rx_interface_if.clk);
            
            uart_top_rx_interface_if.rx = 1'b0;
            repeat(BAUD_RATE_DIVISOR) @(posedge uart_top_rx_interface_if.clk);

            for (int i = 0; i < 8; i++) begin
                uart_top_rx_interface_if.rx = tr.rx_data[i];
                repeat(BAUD_RATE_DIVISOR) @(posedge uart_top_rx_interface_if.clk);
            end

            uart_top_rx_interface_if.rx = 1'b1;
            repeat(BAUD_RATE_DIVISOR) @(posedge uart_top_rx_interface_if.clk);
            
            -> mon_next_event;
        end
    endtask
endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual uart_top_rx_interface uart_top_rx_interface_if;
    event mon_next_event;
    
    function new(mailbox #(transaction) mon2scb_mbox, virtual uart_top_rx_interface uart_top_rx_interface_if
    ,event mon_next_event);
        this.mon2scb_mbox = mon2scb_mbox;
        this.uart_top_rx_interface_if = uart_top_rx_interface_if;
        this.mon_next_event = mon_next_event;
    endfunction

    task run();
        forever begin
            @(mon_next_event);
            tr = new;
            tr.rx_done = uart_top_rx_interface_if.rx_done;
            tr.rx_data = uart_top_rx_interface_if.rx_data;
            
            tr.display("[Mon]"); 
            mon2scb_mbox.put(tr);
        end
    endtask
endclass

class scoreboard;
    transaction expected_tr, actual_tr;
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
            gen2scb_mbox.get(expected_tr);
            mon2scb_mbox.get(actual_tr);
            
            expected_tr.display("[Scb-Exp]");
            actual_tr.display("[Scb-Act]");
            
            if (actual_tr.rx_data == expected_tr.rx_data) begin
                $display("[SCB] PASS: Expect = %0x, Actual = %0x", expected_tr.rx_data, actual_tr.rx_data);
                pass_count++;
            end else begin
                $display("[SCB] FAIL: Expect = %0x, Actual = %0x", expected_tr.rx_data, actual_tr.rx_data);
                fail_count++;
            end
            -> gen_next_event;
        end
    endtask

endclass

class environment;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(transaction) gen2scb_mbox;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    event gen_next_event;
    event mon_next_event;

    function new(virtual uart_top_rx_interface uart_top_rx_interface_if);
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        gen2scb_mbox = new;
        gen = new(gen2drv_mbox, gen2scb_mbox, gen_next_event);
        drv = new(gen2drv_mbox, uart_top_rx_interface_if, mon_next_event);
        mon = new(mon2scb_mbox, uart_top_rx_interface_if, mon_next_event);
        scb = new(mon2scb_mbox, gen2scb_mbox, gen_next_event);
    endfunction

    task report();
        $display("===================================");
        $display("=========== TEST REPORT ===========");
        $display("== Total Transactions: %0d ==", gen.total_count);
        $display("== PASS Count: %0d ==", scb.pass_count);
        $display("== FAIL Count: %0d ==", scb.fail_count);
        $display("===================================");
    endtask

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

module tb_uart_top_rx();
    uart_top_rx_interface uart_top_rx_interface_tb();
    environment env;

    logic clk = 0;

    // uart_top_rx dut(
    //     .clk(uart_top_rx_interface_tb.clk),
    //     .rst(uart_top_rx_interface_tb.rst),
    //     .rx(uart_top_rx_interface_tb.rx),
    //     .rx_data(uart_top_rx_interface_tb.rx_data),
    //     .rx_done(uart_top_rx_interface_tb.rx_done)
    // );

    UART_top dut (
        // tx -> will not connect at this time
        .clk(uart_top_rx_interface_tb.clk),
        .rst(uart_top_rx_interface_tb.rst),
        // .tx_start(),
        // .tx_data(),
        .rx(uart_top_rx_interface_tb.rx),

        // .tx_busy(),
        // .tx(),
        .rx_data(uart_top_rx_interface_tb.rx_data),
        .rx_done(uart_top_rx_interface_tb.rx_done)
        // .baud_tick()
    );

    always #5 uart_top_rx_interface_tb.clk = ~uart_top_rx_interface_tb.clk;

    initial begin
        uart_top_rx_interface_tb.clk = 0;
        env = new(uart_top_rx_interface_tb);
        //env.reset();
        env.run(50);
    end

endmodule
