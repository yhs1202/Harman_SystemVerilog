`timescale 1ns / 1ps

// this module will be merged to counter_controller_unit
module command_controller_unit(
    input clk, rst,
    input [7:0] rx_data,
    input rx_done,
    output enable_cmd,
    output clear_cmd,
    output mode_cmd
    );

    parameter IDLE = 0, CMD = 1;
    reg c_state, n_state;
    reg enable_reg, enable_next;
    reg clear_reg, clear_next;
    reg mode_reg, mode_next;

    assign enable_cmd = enable_reg;
    assign clear_cmd = clear_reg;
    assign mode_cmd = mode_reg;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= 0;
            enable_reg <= 0;
            clear_reg <= 0;
            mode_reg <= 0;
        end
        else begin
            c_state <= n_state;
            enable_reg <= enable_next;
            clear_reg <= clear_next;
            mode_reg <= mode_next;
        end
    end

    always @(*) begin
        n_state = c_state;
        enable_next = enable_reg;
        clear_next = 0;
        mode_next = mode_reg;

        case (c_state)
            IDLE: begin
                if (rx_done) begin
                    n_state = CMD;
                end
            end
            CMD: begin
                case (rx_data)
                    "r": enable_next = ~enable_reg;
                    "R": enable_next = ~enable_reg;
                    "c": clear_next = 1;
                    "C": clear_next = 1;
                    "m": mode_next = ~mode_reg;
                    "M": mode_next = ~mode_reg;
                    default: 
                        begin
                            enable_next = enable_reg;
                            clear_next = 0;
                            mode_next = mode_reg;
                        end
                endcase
                n_state = IDLE;
            end
        endcase
    end
endmodule
