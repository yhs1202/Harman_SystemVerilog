`timescale 1ns/1ps
module instruction_mem (
    input logic [31:0] addr,
    output logic [31:0] instruction_code
);

    logic [31:0] mem [0:31];

    initial begin
        // Program to compute sum of 1 to 10
        // add rd(x5), rs1(x3), rs2(x4)
                                //      func7     rs2    rs1  func3   rd    opcode
        mem[0] = 32'h004182B3;  // 32'b0000_000 0_0100 _0001_1 000 _0010_1 011_0011
        // sub rd(x6), rs1(x5), rs2(x4)
        mem[1] = 32'h409403B3;  // 32'b0100_000 0_1001 _0100_0 000 _0011_1 011_0011

    end

    assign instruction_code = mem[addr[31:2]]; // word aligned
endmodule