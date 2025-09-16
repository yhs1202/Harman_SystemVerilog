`timescale 1ns / 1ps

// Interface for adder_32bit
interface adder_32bit_interface;
    logic [31:0] a, b;
    logic [31:0] sum;
    logic carry; 
endinterface //adder_32bit_interface

// Transaction class for adder_32bit
class transaction;
    // rand -> randomizable variable
    // bit -> 2-state data type (0, 1)
    rand bit [31:0] a, b;
    rand bit [31:0] sum;
    rand bit carry;
    
endclass //transaction

// generate stimulus with transaction class object and drive signals through interface
class generator;
    // virtual -> to use interface in class without port connection
    virtual adder_32bit_interface adder_if;

    // handle for transaction class
    // to create object of transaction class
    // like pointer in C/C++
    // tr.randomize() -> method of class
    transaction tr;

    // new() -> constructor
    function new(virtual adder_32bit_interface intf);
        this.adder_if = intf;
        tr = new();   // instantiate transaction class

    endfunction // new()

    // run() -> main function of generator class
    // generate stimulus in this function
    task run(int count);
        // repeat -> loop
        // 10 times generate stimulus
        repeat (count) begin
            // tr.randomize() -> method of class
            if (!tr.randomize()) begin
                $fatal("Failed to randomize");
            end
            // drive signals in interface
            adder_if.a = tr.a;
            adder_if.b = tr.b;
            // wait for some time
            #10;
            // display results
            $display("a: %h, b: %h, sum: %h, carry: %b",
             adder_if.a, adder_if.b, adder_if.sum, adder_if.carry);
        end
    endtask //run
endclass //generator

module tb_adder_32bit();
    // instance of interface (to connect DUT and class)
    adder_32bit_interface intf();
    
    // instance of generator class
    // to connect interface in class
    generator gen = new(intf);

    adder_32bit dut (
        .a(intf.a),
        .b(intf.b),
        .sum(intf.sum),
        .carry(intf.carry)
    );

    initial begin
        // call run() task of generator class
        gen.run(100);
        #10;
        $finish;
    end

endmodule
