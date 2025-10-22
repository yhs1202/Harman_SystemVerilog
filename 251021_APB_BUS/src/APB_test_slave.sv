`timescale 1ns/1ps
module APB_test_slave (
    // Global Signals
    input logic PCLK,
    input logic PRESET,

    // APB Interface Signals
    input logic [31:0] PADDR,
    input logic PWRITE,
    input logic PENABLE,
    input logic [31:0] PWDATA,
    input logic PSEL,

    output logic [31:0] PRDATA,
    output logic PREADY
);

    // Simple memory for slave
    logic [31:0] memory [0:15];

    // APB Slave behavior
    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            PREADY <= 1'b0;
            PRDATA <= 32'b0;
        end else begin
            // w/o wait states
            PREADY <= 1'b0;
            if (PSEL && PENABLE) begin
                PREADY <= 1'b1;
                if (PWRITE) begin
                    // Write operation
                    memory[PADDR[5:2]] <= PWDATA;
                end else if (!PWRITE) begin
                    // Read operation
                    PRDATA <= memory[PADDR[5:2]];
                end
            end
        end
    end
endmodule

// master : PSEL -> PENABLE
// slave  : PSEL & PREADY
// slave ready : PREADY = 1
// master end : PSEL=0, PENABLE=0
