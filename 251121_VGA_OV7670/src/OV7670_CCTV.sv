`timescale 1ns/1ps

module OV7670_CCTV (
    input logic clk,
    input logic reset,

    // OV7670 Camera Interface
    output logic xclk,
    input logic pclk,
    input logic href,
    input logic vsync,
    input logic [7:0] data,

    // VGA Interface
    output logic h_sync,
    output logic v_sync,
    output logic [3:0] r_port,
    output logic [3:0] g_port,
    output logic [3:0] b_port
);


    logic sys_clk;
    logic DE;
    logic [9:0] pixel_x;
    logic [9:0] pixel_y;

    logic [16:0] rAddr;
    logic [15:0] rData;

    logic we;
    logic [16:0] wAddr;
    logic [15:0] wData;
    
    assign xclk = sys_clk;

    pixel_clk_gen U_PIXEL_CLK_GEN (
        .clk(clk),
        .reset(reset),
        .p_clk(sys_clk)
    );

    VGA_Syncher U_VGA_Syncher (
        .clk(sys_clk),
        .reset(reset),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .DE(DE),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y)
    );


    imgMemReader U_imgMemReader (
        .DE(DE),
        .x(pixel_x),
        .y(pixel_y),
        .imgData(rData),

        .addr(rAddr),
        .r_port(r_port),
        .g_port(g_port),
        .b_port(b_port)
    );

    frame_buffer U_FRAME_BUFFER (
        // write port
        .wclk(pclk),
        .we(we),
        .wAddr(wAddr),
        .wData(wData),
        // read port
        .rclk(sys_clk),
        .oe(1'b1),
        .rAddr(rAddr),
        .rData(rData)
    );


    OV7670_Mem_Controller U_OV7670_Mem_Controller (
        .pclk(pclk),
        .reset(reset),
        // OV7670 Camera Interface
        .href(href),
        .vsync(vsync),
        .data(data),
        // Memory Write Interface
        .mem_we(we),
        .mem_addr(wAddr),
        .mem_wdata(wData)
    );

endmodule