`timescale 1ns/1ps

module pixel_counter (
    input logic clk,
    input logic reset,

    output logic [9:0] h_counter,
    output logic [9:0] v_counter
);

    // Horizontal and Vertical resolution parameters
    parameter H_MAX = 800;  // Total horizontal pixels (including blanking)
    parameter V_MAX = 525;  // Total vertical lines (including blanking)

    always_ff @( posedge clk, posedge reset ) begin
        if (reset) begin
            h_counter <= 0;
            v_counter <= 0;
        end else begin
            if (h_counter == H_MAX - 1) begin
                h_counter <= 0;
                if (v_counter == V_MAX - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end
    
endmodule