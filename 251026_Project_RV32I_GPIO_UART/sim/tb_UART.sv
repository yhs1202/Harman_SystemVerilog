`timescale 1ns / 1ps

// 1. Interface
interface uart_interface();
    logic clk;
    logic rst;
    logic rx;
    logic tx;
    logic [7:0] expected_data; 
    logic [3:0] PADDR;
    logic [31:0] PWDATA;
    logic PWRITE;
    logic PENABLE;
    logic PSEL;
    logic [31:0] PRDATA;
    logic PREADY;
endinterface //uart_interface


// 2. Transaction Class
class transaction;
    bit [7:0] uart_send_data; 
    bit [7:0] uart_received_data;
    bit rx;
    bit tx;

endclass


// 3. Generator Class
class generator;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event gen_next_event;

    int transaction_count = 0;

    bit [7:0] unique_data_queue[$];

    function new(mailbox#(transaction) gen2drv_mbox,
                event gen_next_event);
        this.gen2drv_mbox   = gen2drv_mbox;
        this.gen_next_event = gen_next_event;
        initialize_queue();
    endfunction


    function void initialize_queue();
        bit [7:0] all_values[256];
        foreach (all_values[i]) begin
            all_values[i] = i;
        end
        all_values.shuffle();
        foreach (all_values[i]) begin
            unique_data_queue.push_back(all_values[i]);
        end
        $display("[GEN] Initialized and shuffled 256 unique values.");
    endfunction


    task run(int run_count);
        if (run_count > unique_data_queue.size()) begin
            $fatal("[GEN] Error: Requested %0d transactions, but only %0d unique values are available.",
                   run_count, unique_data_queue.size());
        end

        repeat (run_count) begin
            transaction_count++;
            $display("=================%0d transaction=============", transaction_count); 
            tr = new();
            
            tr.uart_send_data = unique_data_queue.pop_front();
            
            gen2drv_mbox.put(tr);
            $display("[GEN] Sending unique data: 0x%h", tr.uart_send_data); 
            @gen_next_event;
        end
    endtask

endclass


// 4. Driver Class
class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    event drv2mon_event;
    virtual uart_interface intf;

    parameter CLOCK_PERIOD_NS = 10;
    parameter BITPERCLOCK     = 10416;
    parameter BIT_PERIOD      = BITPERCLOCK * CLOCK_PERIOD_NS;

    localparam logic [3:0] SIGNAL_REG_ADDR = 4'h0;
    localparam logic [3:0] WDATA_REG_ADDR  = 4'h4;
    localparam logic [3:0] RDATA_REG_ADDR  = 4'h8;

    localparam int TX_FULL_BIT  = 1; 
    localparam int RX_EMPTY_BIT = 0; 

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual uart_interface intf,
                 event drv2mon_event);
        this.gen2drv_mbox = gen2drv_mbox;
        this.intf = intf;
        this.drv2mon_event = drv2mon_event;
    endfunction

    function string get_apb_state();
        return $sformatf("ADDRESS:%h WRITE:%b ENABLE:%b SEL:%b WDATA:%08h RDATA:%08h READY:%b",
                         intf.PADDR, intf.PWRITE, intf.PENABLE,
                         intf.PSEL, intf.PWDATA, intf.PRDATA,
                         intf.PREADY);
    endfunction

    task reset();
        intf.clk = 0;
        intf.rst = 1;
        intf.rx  = 1;
        intf.tx  = 1;
        repeat (2) @(posedge intf.clk);
        intf.rst = 0;
        @(posedge intf.clk);
        $display("[DRV] Reset asserted");
    endtask

    task uart_sender(bit [7:0] uart_send_data);
        intf.rx = 0;
        #(BIT_PERIOD);
        for (int i = 0; i < 8; i = i + 1) begin
            intf.rx = uart_send_data[i];
            #(BIT_PERIOD);
        end
        intf.rx = 1;
        #(BIT_PERIOD);
    endtask

    task uart_apb_read(input logic [3:0] addr, output logic [31:0] data);
        logic [31:0] read_value;
        @(posedge intf.clk);
        intf.PADDR   = addr;
        intf.PWRITE  = 0;
        intf.PSEL    = 1;
        intf.PENABLE = 0;
        @(posedge intf.clk);
        intf.PENABLE = 1;
        wait (intf.PREADY == 1);
        read_value = intf.PRDATA;
        $display("%s", get_apb_state());
        @(posedge intf.clk);
        intf.PSEL    = 0;
        intf.PENABLE = 0;
        data            = read_value;
    endtask

    task uart_apb_write(input logic [3:0] addr, input logic [31:0] data);
        @(posedge intf.clk);
        intf.PADDR   = addr;
        intf.PWDATA  = data;
        intf.PWRITE  = 1;
        intf.PSEL    = 1;
        intf.PENABLE = 0;
        @(posedge intf.clk);
        intf.PENABLE = 1;
        wait (intf.PREADY == 1);
        $display("%s", get_apb_state());
        @(posedge intf.clk);
        intf.PSEL    = 0;
        intf.PENABLE = 0;
    endtask

    task run();
        logic [31:0] read_data;
        forever begin
            gen2drv_mbox.get(tr);
            intf.expected_data = tr.uart_send_data;
            uart_sender(tr.uart_send_data);
            
            $display("[DRV] Sent 0x%h to RX.", tr.uart_send_data);
            
            $display("[DRV-APB] Check RX FIFO for Data (rx_empty=0).");
            begin
                logic [31:0] current_status;
                do begin
                    uart_apb_read(SIGNAL_REG_ADDR, current_status);
                end while (current_status[RX_EMPTY_BIT] == 1); 
            end
            uart_apb_read(RDATA_REG_ADDR, read_data);
            
            $display("[DRV-APB] Read 0x%h from RX FIFO.", read_data[7:0]);
            
            $display("[DRV-APB] Check TX FIFO is not full (tx_full=0).");
            begin
                logic [31:0] current_status;
                do begin
                    uart_apb_read(SIGNAL_REG_ADDR, current_status);
                end while (current_status[TX_FULL_BIT] == 1); 
            end
            uart_apb_write(WDATA_REG_ADDR, read_data);
            
            $display("[DRV-APB] Wrote 0x%h to TX FIFO.",
                           read_data[7:0]);
            ->drv2mon_event;
        end
    endtask
endclass


// 5. Monitor Class
class monitor;
    mailbox #(transaction) mon2scb_mbox;
    event drv2mon_event;
    virtual uart_interface intf;

    parameter CLOCK_PERIOD_NS = 10;
    parameter BITPERCLOCK     = 10416;
    parameter BIT_PERIOD      = BITPERCLOCK * CLOCK_PERIOD_NS;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual uart_interface intf,
                 event drv2mon_event);
        this.mon2scb_mbox  = mon2scb_mbox;
        this.intf     = intf;
        this.drv2mon_event = drv2mon_event;
    endfunction

    task run();
        localparam bit VERBOSE_DEBUG = 1;
        forever begin
            transaction mon_trans; 
            @(drv2mon_event);
            mon_trans = new();
            mon_trans.uart_send_data = intf.expected_data;

            wait (intf.tx == 0);
            #(BIT_PERIOD + BIT_PERIOD / 2);
            mon_trans.uart_received_data[0] = intf.tx;
            for (int i = 1; i < 8; i = i + 1) begin
                #(BIT_PERIOD);
                mon_trans.uart_received_data[i] = intf.tx;
            end
            #(BIT_PERIOD / 2);
            if (VERBOSE_DEBUG) begin
                $display("[MON] Received TX Data: 0x%h (Expected: 0x%h)", 
                         mon_trans.uart_received_data, mon_trans.uart_send_data);
            end
            @(posedge intf.clk);
            mon2scb_mbox.put(mon_trans); 
        end
    endtask
endclass


// 6. Scoreboard Class
class scoreboard;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_event;
    int pass_unique_count = 0;
    int data_fail_count = 0;
    int duplicate_fail_count = 0;
    int total_transaction_count = 0;
    
    bit seen_values[bit [7:0]]; 

    function new(mailbox#(transaction) mon2scb_mbox, event gen_next_event);
        this.mon2scb_mbox   = mon2scb_mbox;
        this.gen_next_event = gen_next_event;
    endfunction

    task run();
        forever begin
            mon2scb_mbox.get(tr);
            total_transaction_count++;
            
            if (tr.uart_send_data == tr.uart_received_data) begin
                if (seen_values.exists(tr.uart_received_data)) begin
                    $display("[SCR] DUPLICATE FAIL - Expected: 0x%h, Received: 0x%h (Already seen)",
                             tr.uart_send_data, tr.uart_received_data);
                    duplicate_fail_count = duplicate_fail_count + 1;
                end else begin
                    $display("[SCR] PASS - Expected: 0x%h, Received: 0x%h (Unique)",
                             tr.uart_send_data, tr.uart_received_data);
                    pass_unique_count = pass_unique_count + 1;
                    seen_values[tr.uart_received_data] = 1;
                end
            end else begin
                $display("[SCR] DATA FAIL - Expected: 0x%h, Received: 0x%h",
                         tr.uart_send_data, tr.uart_received_data);
                data_fail_count = data_fail_count + 1;
            end
            ->gen_next_event;
        end
    endtask

    task report();
        int total_failures = data_fail_count + duplicate_fail_count;
        real pass_rate   = 0.0;
        string final_status = (total_failures == 0) ? "PASS" : "FAIL";
        
        if (total_transaction_count > 0) begin
            pass_rate = (pass_unique_count * 100.0) / total_transaction_count;
        end

        $display("/////////////////////////////////////////////////////////////");
        $display("/////////////////   UART TESTBENCH REPORT   /////////////////");
        $display("/////////////////////////////////////////////////////////////");
        $display("");
        $display("-------------   TEST SUMMARY   -------------");
        $display("   %-25s : %s", "FINAL STATUS", final_status);
        $display("   %-25s : %0.2f %%", "Pass Rate", pass_rate);
        $display("");
        $display("-------------   COUNT BREAKDOWN   -------------");
        $display("   %-25s : %0d", "Total Transactions", total_transaction_count);
        $display("   %-25s : %0d", "Passed (Unique)", pass_unique_count);
        $display("   %-25s : %0d", "Failed (Data Mismatch)", data_fail_count);
        $display("   %-25s : %0d", "Failed (Duplicate Data)", duplicate_fail_count);
        $display("   %-25s : %0d", "Total Failures", total_failures);
        $display("");
        $display("-------------   UNIQUENESS CHECK   -------------");
        $display("   %-25s : %0d / 256", "Unique Values Seen", seen_values.num());
        if (seen_values.num() != 256 && total_transaction_count == 256 && total_failures == 0) begin
            $display("   WARNING: All 256 transactions passed, but not all unique values were seen.");
        end
        $display("/////////////////////////////////////////////////////////////");
    endtask
endclass


// 7. Environment Class
class environment;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    mailbox #(transaction) mon2scb_mbox;
    event gen_next_event;
    event drv2mon_event;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    virtual uart_interface intf;

    function new(virtual uart_interface intf);
        this.intf = intf;
        gen2drv_mbox = new();
        mon2scb_mbox = new();
        gen = new(gen2drv_mbox, gen_next_event);
        drv = new(gen2drv_mbox, intf, drv2mon_event);
        mon = new(mon2scb_mbox, intf, drv2mon_event);
        scb = new(mon2scb_mbox, gen_next_event);
    endfunction

    task reset();
        drv.reset();
        intf.PADDR   <= 4'bx;
        intf.PWDATA  <= 32'bx;
        intf.PWRITE  <= 1'b0;
        intf.PENABLE <= 1'b0;
        intf.PSEL    <= 1'b0;
        intf.expected_data <= 8'bx; 
        @(posedge intf.clk);
    endtask

    task run();
        fork
            drv.run();
            mon.run();
            scb.run();
        join_none 

        gen.run(10);

        #100ns; 

        scb.report();
        $stop;
    endtask
endclass


// 8. Main Testbench
module tb_UART ();
    uart_interface intf();
    environment env;

    UART_Periph dut (
        .PCLK(intf.clk),
        .PRESET(intf.rst),
        .PADDR(intf.PADDR),
        .PWDATA(intf.PWDATA),
        .PWRITE(intf.PWRITE),
        .PENABLE(intf.PENABLE),
        .PSEL(intf.PSEL),
        .PRDATA(intf.PRDATA),
        .PREADY(intf.PREADY),
        .rx(intf.rx),
        .tx(intf.tx)
    );

    always #5 intf.clk = ~intf.clk;

    initial begin
        intf.clk = 0;
        env = new(intf);
        env.reset();
        env.run();
    end
endmodule
