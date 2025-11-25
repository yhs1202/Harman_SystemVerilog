`timescale 1ns / 1ps
`include "BMP.sv"

module tb_bmp_filter;

  logic clk;
  logic reset;
  logic h_sync;
  logic v_sync;
  logic DE;
  logic [9:0] x;
  logic [9:0] y;
  logic [$clog2(640*480)-1:0] addr;
  logic [23:0] imgData;
  logic [7:0] r_port;
  logic [7:0] g_port;
  logic [7:0] b_port;
  logic [23:0] rgb; 

  // ASCII Art signals
  logic line_ready;
  logic [7:0] ascii_char;
  logic [7:0] line_buf [0:639];

  VGA_Syncher vga_syncher (
    .clk(clk),
    .reset(reset),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .DE(DE),
    .pixel_x(x),
    .pixel_y(y)
  );

  imgRom img_rom (
    .clk(clk),
    .addr(addr),
    .data(imgData)
  );

  imgMemReader img_mem_reader (
    .DE(DE),
    .x(x),
    .y(y),
    .imgData(imgData),
    .addr(addr),
    .r_port(rgb[23:16]),
    .g_port(rgb[15:8]),
    .b_port(rgb[7:0])
    // .r_port(r_port),
    // .g_port(g_port),
    // .b_port(b_port)
  );

  // RGB -> Grayscale
  img_grayscaler img_grayscaler (
    .DE(DE),
    .rgb_in(rgb),
    .rgb_out({r_port, g_port, b_port})
  );

  // RGB -> ASCII
  ascii_art_top U_ascii_art_top (
    .clk(clk),
    .DE(DE),
    .rgb_in(rgb),
    .ascii_char(ascii_char),
    .line_ready(line_ready)
  );

  // RGB -> GRAYSCALE bmp gen
  monitor_bmp monitor_bmp (
    .clk(clk),
    .reset(reset),
    .h_sync(h_sync),
    .v_sync(v_sync),
    .x(x),
    .y(y),
    .r_port(r_port),
    .g_port(g_port),
    .b_port(b_port)
  );



  // Clock and Reset
  always #5 clk = ~clk;
  initial begin
    clk = 0;
    reset = 1;
    #20;
    reset = 0;
  end


  // ASCII Art File Write
  integer fd;
  initial begin
    fd = $fopen("ascii_art.txt", "w");
  end

  always_ff @(posedge clk) begin
    if (line_ready) begin
      for (int i = 0; i < 640; i++) begin
        $fwrite(fd, "%c", U_ascii_art_top.U_ASCII_LINE_BUFFER.line_buf[i]);
      end
      $fwrite(fd, "\r\n");
    end
  end

endmodule


module imgRom (
  input logic clk,
  input logic [$clog2(640*480)-1:0] addr,
  output logic [23:0] data
);

  byte imgData[640*480*3];  // BGR format

  initial begin
    BMP src;
    src = new("img_640x480.bmp", "rb");
    src.read();
    imgData = src.bmpImgData; // write to local memory
    src.close();
  end

  always_ff @(posedge clk) begin
    data <= {imgData[addr*3+2], imgData[addr*3+1], imgData[addr*3]};  // RGB
  end
endmodule


module monitor_bmp (
  input logic clk,
  input logic reset,
  input logic h_sync,
  input logic v_sync,
  input logic [9:0] x,
  input logic [9:0] y,
  input logic [7:0] r_port,
  input logic [7:0] g_port,
  input logic [7:0] b_port

);

  localparam H_SIZE = 640;
  localparam V_SIZE = 480;
  byte imgData[H_SIZE*V_SIZE*3];

  always_ff @(posedge clk) begin
    if (x < H_SIZE && y < V_SIZE) begin
      imgData[(H_SIZE * y + x) * 3 + 2] <= r_port;
      imgData[(H_SIZE * y + x) * 3 + 1] <= g_port;
      imgData[(H_SIZE * y + x) * 3 + 0] <= b_port;
    end
  end



  // Write to BMP file at the end of simulation
    BMP headerSrc;
    BMP target;

  initial begin
    #10;
    headerSrc = new("img_640x480.bmp", "rb");
    target = new("output_640x480.bmp", "wb");
    headerSrc.read();
    @(negedge v_sync)
    target.write(headerSrc.bmpHeader, $size(headerSrc.bmpHeader));
    target.write(imgData, $size(imgData));

    headerSrc.close();
    target.close();
  end
  
endmodule