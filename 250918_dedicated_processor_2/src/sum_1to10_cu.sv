`timescale 1ns/1ps
module sum_1to10_cu (
    input logic clk,
    input logic rst,
    input logic not_iLe10,

    output logic sumSrcSel,
    output logic iSrcSel,
    output logic sumLoad,
    output logic iLoad,
    output logic adderSrcSel,
    output logic OutLoad
);
    
    typedef enum bit [2:0] {
        s0, // i=0; sum=0;
        s1, // i <= 10
        s2, // sum++;
        s3, // i++;
        s4, // out = sum;
        s5  // halt;
    } state;

    state current_state, next_state;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            current_state <= s0;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        sumSrcSel = 0;
        iSrcSel = 0;
        sumLoad = 0;
        iLoad = 0;
        adderSrcSel = 0;
        OutLoad = 0;

       next_state = current_state;

       case (current_state)
            s0: begin
                sumSrcSel = 0;
                iSrcSel = 0;
                sumLoad = 1;
                iLoad = 1;
                adderSrcSel = 0;
                OutLoad = 0;
                next_state = s1;
            end
            s1: begin
                sumSrcSel = 0;
                iSrcSel = 0;
                sumLoad = 0;
                iLoad = 0;
                adderSrcSel = 0;
                OutLoad = 0;
                if (not_iLe10) begin
                    next_state = s5;                    
                end
                else begin
                    next_state = s2;
                end
            end
            s2: begin
                sumSrcSel = 1;
                iSrcSel = 0;
                sumLoad = 1;
                iLoad = 0;
                adderSrcSel = 0;
                OutLoad = 0;
                next_state = s3;
            end
            s3: begin
                sumSrcSel = 0;
                iSrcSel = 1;
                sumLoad = 0;
                iLoad = 1;
                adderSrcSel = 1;
                OutLoad = 0;
                next_state = s4;
            end
            s4: begin
                sumSrcSel = 0;
                iSrcSel = 0;
                sumLoad = 0;
                iLoad = 0;
                adderSrcSel = 0;
                OutLoad = 1;
                next_state = s1;
            end
            s5: begin
                sumSrcSel = 0;
                iSrcSel = 0;
                sumLoad = 0;
                iLoad = 0;
                adderSrcSel = 0;
                OutLoad = 1;
                next_state = s5;
            end
       endcase 
    end
endmodule