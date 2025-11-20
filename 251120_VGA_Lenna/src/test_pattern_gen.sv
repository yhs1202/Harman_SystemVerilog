`timescale 1ns/1ps
module test_pattern_gen #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480
)(
    input logic clk,
    input logic reset,
    input logic [9:0] x,
    input logic [9:0] y,
    input logic DE,
    output logic [11:0] rgb
);

    // Color constants
    localparam logic [3:0]
        C0 = 4'h0,
        C4 = 4'h4,
        C8 = 4'h8,
        CF = 4'hF;

    localparam logic [11:0]
        //            R    G   B
        COL_BLACK  = {C0, C0, C0},
        COL_RED    = {CF, C0, C0},
        COL_GREEN  = {C0, CF, C0},
        COL_BLUE   = {C0, C0, CF},

        COL_GRAY   = {C8, C8, C8},
        COL_YELLOW = {CF, CF, C0},
        COL_CYAN   = {C0, CF, CF},
        COL_MAG    = {CF, C0, CF},
        COL_WHITE  = {CF, CF, CF};

    localparam integer BAR_NUM   = 7;
    localparam integer BAR_WIDTH = H_ACTIVE / BAR_NUM; // 91 (640/7)
    localparam integer BAR_WIDTH_BOTTOM = BAR_WIDTH * 5 / 4; // 113
    localparam integer BAR_WIDTH_BOTTOM2 = BAR_WIDTH / 3;



    always_comb begin
        if (!DE) rgb = 12'h000;
        else begin
            if (y < (V_ACTIVE * 2 / 3)) begin // y < 320
                if      (x < BAR_WIDTH * 1) rgb = COL_WHITE;
                else if (x < BAR_WIDTH * 2) rgb = COL_YELLOW;
                else if (x < BAR_WIDTH * 3) rgb = COL_CYAN;
                else if (x < BAR_WIDTH * 4) rgb = COL_GREEN;
                else if (x < BAR_WIDTH * 5) rgb = COL_MAG;
                else if (x < BAR_WIDTH * 6) rgb = COL_RED;
                else if (x < BAR_WIDTH * 7) rgb = COL_BLUE;
            end
            else if (y < V_ACTIVE * 8 / 11) begin   // y < 349
                if      (x < BAR_WIDTH * 1) rgb = COL_BLUE;
                else if (x < BAR_WIDTH * 2) rgb = COL_BLACK;
                else if (x < BAR_WIDTH * 3) rgb = COL_MAG;
                else if (x < BAR_WIDTH * 4) rgb = COL_BLACK;
                else if (x < BAR_WIDTH * 5) rgb = COL_CYAN;
                else if (x < BAR_WIDTH * 6) rgb = COL_BLACK;
                else if (x < BAR_WIDTH * 7) rgb = COL_WHITE;
            end
            else begin
                if      (x < BAR_WIDTH_BOTTOM * 1)                  rgb = 12'h009;
                else if (x < BAR_WIDTH_BOTTOM * 2)                  rgb = COL_WHITE;
                else if (x < BAR_WIDTH_BOTTOM * 3)                  rgb = 12'h70C;
                else if (x < BAR_WIDTH * 5)                         rgb = COL_BLACK;
                else if (x < BAR_WIDTH * 5 + BAR_WIDTH_BOTTOM2 * 1) rgb = 12'h111;
                else if (x < BAR_WIDTH * 5 + BAR_WIDTH_BOTTOM2 * 2) rgb = 12'h222;
                else if (x < BAR_WIDTH * 5 + BAR_WIDTH_BOTTOM2 * 3) rgb = 12'h333;
                else if (x < BAR_WIDTH * 7)                         rgb = COL_BLACK;
            end
        end
    end
endmodule

