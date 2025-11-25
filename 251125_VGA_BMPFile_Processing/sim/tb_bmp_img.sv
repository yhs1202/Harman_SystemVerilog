`timescale 1ns / 1ps
`include "BMP.sv"

module tb_bmp_img;
  BMP  src;
  BMP  target;

  byte imgData[640*480*3];

  initial begin
    src = new("img_640x480.bmp", "rb");
    target = new("target_640x480.bmp", "wb");

    src.read();
    imgData = src.bmpImgData;

    // ISP
    // ...
    // ...

    target.write(src.bmpHeader, $size(src.bmpHeader));
    target.write(imgData, $size(imgData));
    src.close();
    target.close();

    $finish;
  end

endmodule
