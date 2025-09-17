`timescale 1ns / 1ps

module counter_control_unit (
    input logic clk,
    input logic rst,
    input logic ALt10,
    output logic AsrcSel,
    output logic ALoad,
    output logic OutBufSel
);
    typedef enum bit [2:0] {
        s0, // A = 0;
        s1, // A < 10;
        s2, // out = A;
        s3, // A = A + 1;
        s4  // halt;
    } state_t;

    state_t current_state, next_state;

    always_ff @ (posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= s0;
        end else begin
            current_state <= next_state;
        end
    end


    always_comb begin
        AsrcSel = 0;
        ALoad = 0;
        OutBufSel = 0;
        
        next_state = current_state;
        case (current_state)
            s0 : begin
                AsrcSel = 0;
                ALoad = 1;
                OutBufSel = 0;
                next_state = s1;
            end
            s1 : begin
                ALoad = 0;
                OutBufSel = 0;
                if (ALt10) begin
                    next_state = s2;    // A < 10
                end
                else begin
                    next_state = s4;
                end
            end
            s2 : begin
                ALoad = 0;
                OutBufSel = 1;
                next_state = s3;
            end
            s3 : begin
                AsrcSel = 1;
                ALoad = 1;
                OutBufSel = 0;
                next_state = s1;
            end
            s4 : begin
                ALoad = 0;
                OutBufSel = 1;
                next_state = s4;
            end
        endcase
    end

endmodule