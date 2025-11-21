`timescale 1ns / 1ps
module imgROM (
    input logic clk,
    input logic [$clog2(320*240-1):0] addr,
    output logic [15:0] data
);

  localparam H_SIZE = 320;
  localparam V_SIZE = 240;

  logic [15:0] mem[0:H_SIZE*V_SIZE-1];

  initial begin
    $readmemh("./Lenna.mem", mem);
  end

  // assign data = mem[addr];
  // Synchronous read
  always_ff @(posedge clk) begin
    data <= mem[addr];
  end

endmodule
