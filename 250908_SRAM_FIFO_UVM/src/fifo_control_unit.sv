`timescale 1ns/1ps
module fifo_control_unit #(
    parameter DEPTH = 8,
    localparam ADDR_WIDTH = $clog2(DEPTH)
)(

    input logic clk,
    input logic rst,
    input logic w_en,
    input logic r_en,
    output logic full,
    output logic empty,
    output logic [ADDR_WIDTH-1:0] w_addr,
    output logic [ADDR_WIDTH-1:0] r_addr
);

    logic [ADDR_WIDTH-1:0] w_ptr_reg, w_ptr_next;
    logic [ADDR_WIDTH-1:0] r_ptr_reg, r_ptr_next;
    logic full_reg, full_next;
    logic empty_reg, empty_next;

    assign w_addr = w_ptr_reg;
    assign r_addr = r_ptr_reg;
    assign full = full_reg;
    assign empty = empty_reg;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg <= 0;
            empty_reg <= 1;
        end
        else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg <= full_next;
            empty_reg <= empty_next;
        end
    end

    always_comb begin
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next = full_reg;
        empty_next = empty_reg;

        case ({w_en, r_en})
            2'b01: begin
                // Read operation
                if (!empty_reg) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next = 0;
                    if (r_ptr_next == w_ptr_reg) begin
                        empty_next = 1;
                    end
                end
            end
            2'b10: begin
                // Write operation
                if (!full_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 0;
                    if (w_ptr_next == r_ptr_reg) begin
                        full_next = 1;
                    end
                end
            end
            2'b11: begin
                // Invalid state
                if (full_reg) begin
                    r_ptr_next = r_ptr_reg + 1;
                    full_next = 0;
                end else if (empty_reg) begin
                    w_ptr_next = w_ptr_reg + 1;
                    empty_next = 0;
                end else begin
                    w_ptr_next = w_ptr_reg + 1;
                    r_ptr_next = r_ptr_reg + 1;
                end
            end
        endcase
    end
endmodule