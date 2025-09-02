`timescale 1ns / 1ps
module counter_controller_unit(
    input clk, rst,
    input btn_enable, btn_clear, btn_mode,

    output enable, clear, mode
    );

    parameter IDLE = 0, CMD = 1;

    reg c_state, n_state;
    reg c_enable, n_enable;
    reg c_clear, n_clear;
    reg c_mode, n_mode;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            c_enable <= 0;
            c_clear <= 0;
            c_mode <= 0;    // 0: up
        end
        else begin
            c_state <= n_state;
            c_enable <= n_enable;
            c_clear <= n_clear;
            c_mode <= n_mode;
        end
    end

    always @(*) begin
        n_state = c_state;
        n_enable = c_enable;
        n_clear = 0;
        n_mode = c_mode;

        case (c_state)
            IDLE: begin
                if (btn_enable | btn_clear | btn_mode) begin
                    if (btn_enable) begin
                        n_enable = ~c_enable;
                    end
                    if (btn_clear) begin
                        n_clear = 1;
                    end
                    if (btn_mode) begin
                        n_mode = ~c_mode;
                    end
                end
            end
        endcase
    end

    assign enable = c_enable;
    assign clear = c_clear;
    assign mode = c_mode;


endmodule
