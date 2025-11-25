module ascii_art_top (
    input  logic clk,
    input  logic DE,
    input  logic [23:0] rgb_in,

    output logic [7:0] ascii_char,
    output logic line_ready
);

  logic [23:0] gray_rgb;
  logic [7:0] gray;
  assign gray = gray_rgb[7:0];

  logic [7:0] ascii;
  logic [7:0] line_buf [0:639];
  logic line_end;

  // 1. RGB -> Grayscale
  img_grayscaler U_GRAYSCALER(
      .DE(DE),
      .rgb_in(rgb_in),
      .rgb_out(gray_rgb)    // 24-bit Grayscale RGB
  );


  // 2. Grayscale -> ASCII
  ascii_mapper U_ASCII_MAPPER(
      .DE(DE),
      .gray(gray),
      .ascii_out(ascii)
  );

  // 3. Pixel Counter, Line End Signal
  logic [9:0] x;  // x pixel position (0~639)
  always_ff @(posedge clk) begin
    if (!DE) x <= 0;
    else if (x == 639) x <= 0;
    else x <= x + 1;
  end

  assign line_end = (x == 639) && DE;

  // 4. Line Buffer
  ascii_line_buffer U_ASCII_LINE_BUFFER(
      .clk(clk),
      .DE(DE),
      .ascii_in(ascii),
      .line_end(line_end),
      .line_buf(line_buf),
      .line_ready(line_ready)
  );

  assign ascii_char = ascii;

endmodule
