`timescale 1ns/1ps
module sum_1to10_with_regfile_cu (
    input logic clk,
    input logic rst,

    input logic iLe10,

    output logic R1SrcSel,
    output logic [1:0] r_addr_0,
    output logic [1:0] r_addr_1,
    output logic w_en,
    output logic [1:0] w_addr,
    output logic OutLoad
);

    typedef enum bit [2:0] {
        s0_i,   // i=0;
        s0_sum, // sum=0; 
        // s1,     // i<=10
        s2,     // sum += i; i<=10;
        s3,     // i++;
        s4,     // out = sum;
        s5      // halt;
    } state;

    state current_state, next_state;

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            current_state <= s0_i;
        end else begin
            current_state <= next_state;
        end
    end

    always_comb begin
        R1SrcSel = 0;
        r_addr_0 = 2'b00;
        r_addr_1 = 2'b00;
        w_en = 0;
        w_addr = 2'b00;
        OutLoad = 0;

       next_state = current_state;

       case (current_state)
            // int i=0;
            s0_i: begin
                R1SrcSel = 0;
                r_addr_0 = 2'b00; // $0
                r_addr_1 = 2'b00;
                w_en = 1;
                w_addr = 2'b10; // i
                OutLoad = 0;
                next_state = s0_sum;
            end
            // int sum=0;
            s0_sum: begin
                R1SrcSel = 0;
                r_addr_0 = 2'b00; // $0
                r_addr_1 = 2'b00;
                w_en = 1;
                w_addr = 2'b01; // sum
                OutLoad = 0;
                next_state = s2;
            end
            /*
            // i<=10;
            s1: begin
                R1SrcSel = 0;
                r_addr_0 = 2'b10; // i
                r_addr_1 = 2'b00;
                w_en = 0;
                w_addr = 2'b00;
                OutLoad = 0;
                next_state = s2;
            end
            */
            // sum += i; i<=10;
            s2: begin
                R1SrcSel = 0;
                r_addr_0 = 2'b01; // sum
                r_addr_1 = 2'b10; // i
                OutLoad = 0;
                if (iLe10) begin
                    w_en = 1;
                    w_addr = 2'b01; // sum
                    next_state = s3;
                end
                else begin
                    next_state = s5;                   
                end
            end

            // i++;
            s3: begin
                R1SrcSel = 1;
                r_addr_0 = 2'b10; // i
                r_addr_1 = 2'b10;
                w_en = 1;
                w_addr = 2'b10; // i
                OutLoad = 0;
                next_state = s4;
            end
            // out = sum;
            s4: begin
                R1SrcSel = 0;
                r_addr_0 = 2'b01; // sum
                r_addr_1 = 2'b00;
                w_en = 0;
                w_addr = 2'b00;
                OutLoad = 1;
                next_state = s2;
            end
            // halt;
            s5: begin
                R1SrcSel = 0;
                r_addr_0 = 2'b01; // $sum
                r_addr_1 = 2'b00;
                w_en = 0;
                w_addr = 2'b00;
                OutLoad = 1;
                next_state = s5;
            end
       endcase 
    end
endmodule