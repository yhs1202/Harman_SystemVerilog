`timescale 1ns / 1ps

interface register_8bit_if;
    logic clk;
    logic rst;
    logic w_en;
    logic [7:0] d;
    logic [7:0] q;
endinterface // register_8bit_if

class transaction;
    rand bit w_en;
    rand bit [7:0] d;

endclass // transaction

class generator;

    transaction tr;
    mailbox #(transaction) mbx;

    function new(mailbox #(transaction) mbx);
        this.mbx = mbx;
    endfunction // new()

    task run(int count);
        repeat (count) begin
            tr = new();
            // if (!tr.randomize()) begin
            //     $fatal("Failed to randomize");
            // end
            assert (tr.randomize()) else begin
                $fatal("Failed to randomize");
            end
            mbx.put(tr);
        end
    endtask // run
endclass // generator

class driver;
    transaction tr;
    mailbox #(transaction) mbx;
    virtual register_8bit_if intf;

    function new(mailbox #(transaction) mbx, virtual register_8bit_if intf);
        this.mbx = mbx;
        this.intf = intf;
    endfunction // new()

    task reset();
        // drive reset signal
        intf.rst = 1;
        intf.w_en = 0;
        intf.d = 0;
        #10;
        intf.rst = 0;
    endtask // reset

    task run();
        // drive signals based on mailbox transactions
        forever begin
            mbx.get(tr); // blocking get if no transaction available
            intf.w_en = tr.w_en;
            intf.d = tr.d;
            @(negedge intf.clk); // wait for clock edge
        end
    endtask // run
endclass // driver

class environment;
    generator gen;
    driver drv;
    mailbox #(transaction) mbx;
    virtual register_8bit_if intf;

    function new(virtual register_8bit_if intf);
        mbx = new();
        gen = new(mbx);
        drv = new(mbx, intf);
    endfunction //new()

    task run(int count);
        drv.reset();
        fork
            gen.run(count);
            drv.run(); // run forever -> repeat not needed
        join_any    // wait for any to finish
        #100;
        $stop;
    endtask // run
endclass // environment


module tb_register_8bit();
    register_8bit_if intf();
    environment env;

    register_8bit dut (
        .clk(intf.clk),
        .rst(intf.rst),
        .w_en(intf.w_en),
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
