`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic [ 2:0] strb,
    input  logic        we,
    output logic [31:0] rData,
    input  logic [ 7:0] addr,
    input  logic [31:0] wData
);
    logic [7:0] mem[0:2**8-1];

    always_ff @(posedge clk) begin
        if (we) begin
            // mem[addr] <= mem[addr];
            case (strb)
                3'b000: mem[addr] <= wData[7:0];  // byte
                3'b001: {mem[addr+1], mem[addr]} <= wData[15:0]; // half, little-endian
                3'b010: {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]} <= wData; // word, little-endian
                default: mem[addr] <= 8'bx; // undefined
            endcase
        end
    end

    always_comb begin
        rData = 0;
        case (strb)
            // byte, ubyte
            3'b000: rData = {{24{mem[addr][7]}}, mem[addr+0]};  // sign-extend
            // ubyte
            3'b100: rData = {24'b0, mem[addr+0]};
            // half
            3'b001: rData = {{16{mem[addr+1][15]}}, mem[addr+1], mem[addr]};  // sign-extend
            // uhalf
            3'b101: rData = {16'b0, mem[addr+1], mem[addr]};
            // word
            3'b010: rData = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]}; // little-endian
            default: rData = 32'bx; // undefined
        endcase
    end
endmodule
