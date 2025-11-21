`timescale 1ns / 1ps

module pixel_clk_gen (
    input  logic clk,
    input  logic reset,
    output logic p_clk
);

  logic [1:0] p_counter;

  always_ff @(posedge clk, posedge reset) begin
    if (reset) begin
      p_counter <= 0;
    end else begin
      if (p_counter == 3) begin  // Divide by 4 (25MHz from 100MHz)
        p_counter <= 0;
        p_clk <= 1;
      end else begin
        p_counter <= p_counter + 1;
        p_clk <= 0;
      end
    end
  end

endmodule

