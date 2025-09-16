`timescale 1ns / 1ps

// 1. Interface for adder_8bit
interface add_sub_if;
    logic [7:0] a;
    logic [7:0] b;
    logic mode;
    logic [7:0] sum;
    logic carry_out;
    
endinterface // add_sub_if

// 2. Transaction class for adder_8bit
class transaction;
    // stimulus data for DUT
    // rand -> randomizable variable (tr.randomize() -> rand type variable will be changed randomly)
    // randc -> randomizable variable with cyclic property (all possible values will be generated before repeating any value)
    rand bit [7:0] a;
    rand bit [7:0] b;
    rand bit mode; // 0 -> add, 1 -> sub
    rand bit [7:0] sum;
    rand bit carry_out;

    // constraint
    // to limit the random values
    constraint c_sum {
        sum < 8'hF0; // sum < 240
    }
    constraint c_a_b {
        a > b; // a > b
    }

endclass // transaction

// 3. Generate stimulus with transaction class object and drive signals through interface
class generator;
    transaction tr; // handle for transaction class

    // 4. Communication between generator and monitor (mailbox)
    // to send transaction object to monitor class
    // mailbox -> FIFO queue
    // mailbox #(/* transaction type */) mbx;
    mailbox #(transaction) gen2drv_mbx;

    // virtual add_sub_if add_sub_if; // handle for interface -> substitute with mailbox

    function new(mailbox #(transaction) mbx);
        // add_sub_if = new.add_sub_if(); -> substitute with mailbox
        this.gen2drv_mbx = mbx;
    endfunction // new()

    task run(int count);
        tr = new(); // instantiate transaction class
        repeat (count) begin
            if (!tr.randomize()) begin
                $fatal("Failed to randomize");
            end
            // send transaction object to monitor class
            gen2drv_mbx.put(tr);
            // wait for some time
            #10;
            // display results
            // $display("a: %h, b: %h, mode: %b, sum: %h, carry_out: %b", 
            // add_sub_if.a, add_sub_if.b, add_sub_if.mode, add_sub_if.sum, add_sub_if.carry_out);
        end
    endtask // run
endclass // generator


// 5-2. driver class
class driver;
    transaction tr;
    virtual add_sub_if add_sub_if; // handle for interface
    mailbox #(transaction) gen2drv_mbx; // handle for mailbox

    function new(mailbox #(transaction) mbx, virtual add_sub_if intf);
        this.add_sub_if = intf;
        this.gen2drv_mbx = mbx;
    endfunction // new()

    task reset();
        add_sub_if.a = 8'h00;
        add_sub_if.b = 8'h00;
        add_sub_if.mode = 1'b0;
        // #10;
    endtask // reset

    task drive();
        // get transaction object from mailbox
        gen2drv_mbx.get(tr);
        add_sub_if.a = tr.a;
        add_sub_if.b = tr.b;
        add_sub_if.mode = tr.mode;
        #10;
    endtask // drive
endclass // driver


// 6. Environment class
// to instantiate generator and driver class and connect them
class environment;
    generator gen;
    driver drv;
    mailbox #(transaction) mbx;
    function new(virtual add_sub_if intf);
        mbx = new();
        gen = new(mbx);
        drv = new(mbx, intf);
    endfunction // new()

    task run(int count);
        fork
            begin
                drv.reset();
                repeat (count) begin
                    drv.drive();
                    // #10;
                end
            end
            gen.run(count);
        join_any
        $stop;
    endtask // run
endclass // environment

module tb_adder_8bit_mode();
    // instance of interface (to connect DUT and class)
    add_sub_if intf();

    // instance of environment class
    environment env;

    // instance of DUT
    adder_8bit_mode dut (
        .a(intf.a),
        .b(intf.b),
        .mode(intf.mode),
        .sum(intf.sum),
        .carry_out(intf.carry_out)
    );

    initial begin
        env = new(intf);
        env.run(50); // generate test vectors
    end
endmodule
