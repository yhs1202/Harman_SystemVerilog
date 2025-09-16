`timescale 1ns / 1ps

interface sram_if;
    logic clk;
    logic rst;
    logic w_en;
    logic [3:0] addr;   // added address from register_8bit
    logic [7:0] d;
    logic [7:0] q;
endinterface // sram_if

class transaction;
    rand bit w_en;
    rand bit [3:0] addr;
    rand bit [7:0] d;
    // read only -> not randomized
    bit [7:0] q;

    // constraints
    constraint addr_limit {
        addr inside {[4:12]};
    }

    constraint w_data_limit {
        d inside {[0:100]};
    }

    constraint write_chance {
        // 70% chance to read
        w_en dist {0 := 3, 1 := 7};
        // w_en dist {0 :/ 3, 1 :/ 7}; // alternative syntax
    }

    // display task
    task display(string name);
        $display("[%t] [%s]: w_en = %0b, addr = %h, d = %0h, q = %0h", $time, name, w_en, addr, d, q);
    endtask // display

endclass // transaction

class generator;

    transaction tr;
    mailbox #(transaction) mbx_gen2drv;

    // event
    event gen_next_event;   // to synchronize generator and scoreboard

    // counter for reporting
    int sent_count = 0;

    function new(mailbox #(transaction) mbx_gen2drv, event gen_next_event);
        this.mbx_gen2drv = mbx_gen2drv;
        this.gen_next_event = gen_next_event;
    endfunction // new()

    task run(int count);
        repeat (count) begin
            sent_count++;
            tr = new();

            assert (tr.randomize()) else begin
                $fatal("Failed to randomize");
            end
            mbx_gen2drv.put(tr);
            tr.display("GEN");
            @(gen_next_event); // wait for scoreboard to consume transaction
        end
    endtask // run
endclass // generator

class driver;
    transaction tr;
    mailbox #(transaction) mbx_gen2drv;
    virtual sram_if intf;

    function new(mailbox #(transaction) mbx_gen2drv, virtual sram_if intf);
        this.mbx_gen2drv = mbx_gen2drv;
        this.intf = intf;
    endfunction // new()

    task reset();
        // drive reset signal
        intf.addr = 0;
        intf.w_en = 1;
        intf.d = 0;

        // reset sequence
        for (int i = 0; i < 16; i++) begin
            @(posedge intf.clk);
            intf.w_en = 1;
            intf.addr = i;
            intf.d = 8'h0;
        end
        @(posedge intf.clk);
        intf.w_en = 0;
        #10;
    endtask // reset

    task run();
        // drive signals based on mailbox transactions
        forever begin
            mbx_gen2drv.get(tr); // blocking get if no transaction available
            intf.addr = tr.addr;
            intf.w_en = tr.w_en;
            intf.d = tr.d;
            tr.display("DRV");
            @(posedge intf.clk); // wait for clock edge
        end
    endtask // run
endclass // driver


// monitor class
// receives signals from DUT and displays them
class monitor;
    transaction tr;
    virtual sram_if intf;
    mailbox #(transaction) mbx_mon2scb;

    function new(mailbox #(transaction) mbx_mon2scb, virtual sram_if intf);
        this.intf = intf;
        this.mbx_mon2scb = mbx_mon2scb;
    endfunction // new()

    task run();
        // continuously
        forever begin
            // monitor signals from DUT
            tr = new();
            @(posedge intf.clk);
            
            #1;
            tr.addr = intf.addr;
            tr.w_en = intf.w_en;
            tr.d = intf.d;  // capture d and w_en
            tr.q = intf.q;  // capture q after clk edge
            tr.display("MON");

            // send transaction object to scoreboard class
            mbx_mon2scb.put(tr);
        end
    endtask // run
endclass // monitor


// scoreboard class
// compares transactions from generator and monitor
class scoreboard;
    transaction tr;
    mailbox #(transaction) mbx_mon2scb;
    event gen_next_event;

    // no DUT interface needed

    // counters for reporting
    int passed_count = 0;
    int failed_count = 0;

    // buffer to hold expected values
    byte addr_mem [16]; // expected memory content


    function new(mailbox #(transaction) mbx_mon2scb, event gen_next_event);
        this.mbx_mon2scb = mbx_mon2scb;
        this.gen_next_event = gen_next_event;
    endfunction // new()

    task run();
        // compare transactions from generator and monitor if w_en is high
        // in real testbench, we would compare with expected values
        forever begin
            mbx_mon2scb.get(tr); // blocking get if no transaction available
            // compare tr with expected values
            // for simplicity, we just display the monitored transaction here
            tr.display("SCB");
            if (tr.w_en) begin
                addr_mem[tr.addr] = tr.d; // update expected memory content
                $display("[INFO]: Write operation at addr = %0h, data = %0h", tr.addr, tr.d);
            end else begin
                // expected q should be equal to d if w_en is high
                if (addr_mem[tr.addr] == tr.q) begin
                    $display("[PASS]: q = %0h as expected, addr = %0h", tr.q, tr.addr);
                    passed_count++;
                end else begin
                    $error("[FAIL] Scoreboard Error: Expected q = %0h, Got q = %0h, addr = %0h", addr_mem[tr.addr], tr.q, tr.addr);
                    failed_count++;
                end
                $display("Scoreboard Info: w_en=0, no write operation");
            end
            -> gen_next_event; // notify generator to produce next transaction
        end
    endtask // run
endclass // scoreboard


class environment;
    generator gen;
    driver drv;
    mailbox #(transaction) mbx_gen2drv;
    mailbox #(transaction) mbx_mon2scb;
    monitor mon;
    scoreboard scb;
    // event
    event gen_next_event;   // to synchronize generator and driver -> scoreboard

    function new(virtual sram_if intf);
        mbx_gen2drv = new();
        mbx_mon2scb = new();
        gen = new(mbx_gen2drv, gen_next_event);
        drv = new(mbx_gen2drv, intf);
        // drv = new(mbx_gen2drv, intf, gen_next_event);
        mon = new(mbx_mon2scb, intf);
        scb = new(mbx_mon2scb, gen_next_event);
    endfunction //new()

    // report task
    task report();
        // report the status of all components
        $display("=================== Environment Report ==================");
        $display("Total transactions processed: %d", gen.sent_count);
        $display("Passed transactions:          %d", scb.passed_count);
        $display("Failed transactions:          %d", scb.failed_count);
        $display("==========================================================");
    endtask // report

    task run(int count);
        drv.reset();
        fork
            gen.run(count);
            drv.run(); // run forever -> repeat not needed
            mon.run();
            scb.run();
        join_any    // wait for any to finish
        report();
        #10;
        $stop;
    endtask // run
endclass // environment


module tb_SRAM();
    sram_if intf();
    environment env;

    SRAM dut (
        .clk(intf.clk),
        .rst(intf.rst),
        .w_en(intf.w_en),
        .addr(intf.addr),
        .d(intf.d),
        .q(intf.q)
    );

    always #5 intf.clk = ~intf.clk;

    initial begin
        intf.clk = 0;
        env = new(intf);
        env.run(100);
    end

endmodule
