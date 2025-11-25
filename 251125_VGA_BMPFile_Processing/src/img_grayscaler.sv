`timescale 1ns / 1ps
module img_grayscaler (
    input logic DE,
    input logic [23:0] rgb_in,
    output logic [23:0] rgb_out
);

  logic [7:0] R8, G8, B8;
  logic [15:0] sum;
  logic [ 7:0] gray;

  // Convert RGB to Grayscale
  always_comb begin
    if (!DE) rgb_out = 24'b0;
    else begin
      // Expand 8-bit RGB to 8-bit for calculation
      R8 = rgb_in[23:16];
      G8 = rgb_in[15:8];
      B8 = rgb_in[7:0];

      // sum = (R8 * 8'd51 + G8 * 8'd179 + B8 * 8'd26);  // Weighted sum
      // Using bit shifts for multiplication by constants
      sum = (R8 << 5) + (R8 << 4) + (R8 << 1) + (R8) +            // R8 * (32 + 16 + 2 + 1) = R8 * 51
            (G8 << 7) + (G8 << 5) + (G8 << 4) + (G8 << 1) + G8 +  // G8 * (128 + 32 + 16 + 2 + 1) = G8 * 179
            (B8 << 4) + (B8 << 3) + (B8 << 1);                    // B8 * (16 + 8 + 2) = B8 * 26

      gray = sum[15:8];  // Take the upper 8 bits as the grayscale value
      rgb_out = {
        gray, gray, gray
      };  // Replicate gray value across R, G, B for VGA output
    end
  end

endmodule
