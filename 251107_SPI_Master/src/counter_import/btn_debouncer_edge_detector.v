`timescale 1ns / 1ps
module btn_debounce_edge_detector (
    input clk, rst,
    input btn_in,
    output btn_out
);

    localparam [2:0] IDLE = 3'b000,
                        A = 3'b001,
                        B = 3'b010,
                        C = 3'b011,
                        D = 3'b100;
    
    reg [2:0] c_state, n_state;
    reg c_flag, n_flag; // if output is reg type, it should be declared as feedback structure
    
    reg c_btn_out, n_btn_out;

    assign btn_out = c_btn_out;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            c_flag <= 0;
            c_btn_out <= 0;
        end
        else begin
            c_state <= n_state;
            c_flag <= n_flag;
            c_btn_out <= n_btn_out;
        end
    end

    always @(*) begin
        n_state = c_state;
        n_flag = c_flag;
        n_btn_out = 0;

        case (c_state)
            IDLE: begin
                n_flag = 0;         // moore -> output assign should be inside state define statement
                if (btn_in) begin
                    n_state = A;    // mealy -> output assign should be inside if statement
                end else begin
                    n_state = IDLE;
                end
            end
            A: begin
                n_flag = 0;
                if (btn_in) begin
                    n_state = B;
                end else begin
                    n_state = IDLE;
                end
            end
            B: begin
                n_flag = 0;
                if (btn_in) begin
                    n_state = C;
                end else begin
                    n_state = IDLE;
                end
            end
            C: begin
                n_flag = 0;
                if (btn_in) begin
                    n_btn_out = 1;  // 1번만 발생하기 위해
                    n_state = D;
                end else begin
                    n_state = IDLE;
                end
            end
            D: begin
                n_flag = 1;
                if (btn_in) begin
                    n_state = D;
                end else begin
                    n_state = IDLE;
                end
            end
        endcase
    end

    
endmodule