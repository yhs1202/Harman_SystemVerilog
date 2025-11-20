`timescale 1ns / 1ps
module img_grayscaler (
    input logic DE,
    input logic [11:0] rgb_in,
    output logic [11:0] rgb_out
);

  logic [7:0] R8, G8, B8;
  logic [15:0] sum;
  logic [ 7:0] gray;

  // Convert RGB to Grayscale
  always_comb begin
    if (!DE) rgb_out = 12'b0;
    else begin
      // Expand 4-bit RGB to 8-bit for calculation
      R8 = {rgb_in[11:8], rgb_in[11:8]};
      G8 = {rgb_in[7:4], rgb_in[7:4]};
      B8 = {rgb_in[3:0], rgb_in[3:0]};

      sum = (R8 * 8'd51 + G8 * 8'd179 + B8 * 8'd26);  // Weighted sum
      gray = sum[15:8];  // Take the upper 8 bits as the grayscale value
      rgb_out = {
        gray[7:4], gray[7:4], gray[7:4]
      };  // Replicate gray value across R, G, B for VGA output
    end
  end

endmodule
