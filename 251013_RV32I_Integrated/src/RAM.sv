`timescale 1ns/1ps
`include "define.svh"
parameter MEM_BYTE_SIZE = 256;

// Temporary implementation of data memory
// TODO: Replace with dual-port RAM
module RAM (
    input logic clk,
    input logic MemRead,
    input logic MemWrite,
    input logic [2:0] func3, // 0-> byte, 1-> halfword, 2-> word, 4-> byte unsigned, 5-> halfword unsigned
    input logic [31:0] addr,
    input logic [31:0] w_data,

    output logic [31:0] r_data
);

    (* ram_style = "block" *) logic [7:0] mem [0:MEM_BYTE_SIZE - 1];

    initial begin
        for (int i = 0; i < MEM_BYTE_SIZE; i++) begin
            // mem[i] = i + 8'd20; // Initialize 
            mem[i] = 8'b0;
        end
    end


    // Write operation (Store)
    always_ff @(posedge clk) begin : MemoryAccess
        if (MemWrite) begin
            case (func3)
                `F3_BYTE: mem[addr] <= w_data[7:0]; // Store byte
                `F3_HALF: {mem[addr+1], mem[addr]} <= w_data[15:0]; // Store halfword
                `F3_WORD: {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= w_data; // Store word
                default: mem[addr] <= 8'bx; // Invalid operation
            endcase
        end
    end
    always_comb begin
        r_data = 32'b0; // Default value
        if (MemRead) begin
            case (func3)
               `F3_BYTE: r_data = {{24{mem[addr][7]}}, mem[addr]};    // sign(msb)-extend
               `F3_HALF: r_data = {{16{mem[addr+1][7]}}, mem[addr+1], mem[addr]};
               `F3_WORD: r_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};
               `F3_UBYTE: r_data = {24'b0, mem[addr]};
               `F3_UHALF: r_data = {16'b0, mem[addr+1], mem[addr]};
                default: r_data = 32'bx; // Invalid operation
            endcase
        end
    end
endmodule