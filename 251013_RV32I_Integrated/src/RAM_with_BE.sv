`timescale 1ns/1ps
parameter MEM_WORD_SIZE = 256;

// Word Aligned RAM w/ byte_enable signal
// TODO: Integrate dual-port Memory to support simultaneous read/write

module RAM_with_BE (
    input logic clk,
    input logic MemRead,
    input logic MemWrite,
    input logic [3:0] byte_enable, // byte enable signal for each byte in a word
    input logic [31:0] addr,
    input logic [31:0] w_data,

    output logic [31:0] r_data
);

    (* ram_style = "block" *) logic [31:0] mem [0:MEM_WORD_SIZE - 1];

    initial begin
        for (int i = 0; i < MEM_WORD_SIZE; i++) begin
            mem[i] = 32'b0;
        end
    end

    // Write operation (Store)
    always_ff @(posedge clk) begin : MemoryAccess
        if (MemWrite) begin
            for (int i = 0; i < 4; i++) begin
                if (byte_enable[i])
                    mem[addr][i*8 +: 8] <= w_data[i*8 +: 8];
            end
        end
    end
    always_comb begin
        r_data = 32'b0; // Default value
        if (MemRead) begin
            r_data = mem[addr];
        end
    end
endmodule