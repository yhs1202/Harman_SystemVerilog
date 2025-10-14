`timescale 1ns / 1ps

module RAM (
    input  logic        clk,
    input  logic [ 1:0] strb,
    input  logic        we,
    input  logic [ 7:0] rAddr,
    output logic [31:0] rData,
    input  logic [ 7:0] wAddr,
    input  logic [31:0] wData
);
    logic [7:0] mem[0:2**8-1];

    always_ff @(posedge clk) begin
        if (we) begin
            mem[wAddr] <= mem[wAddr];
            case (strb)
                2'b00: begin
                    mem[wAddr+0] <= wData[7:0];  // byte
                end
                2'b01: begin  // half
                    mem[wAddr+0] <= wData[7:0];
                    mem[wAddr+1] <= wData[15:8];
                end
                2'b10: begin  // word
                    mem[wAddr+0] <= wData[7:0];
                    mem[wAddr+1] <= wData[15:8];
                    mem[wAddr+2] <= wData[23:16];
                    mem[wAddr+3] <= wData[31:24];
                end
            endcase
        end
    end

    always_comb begin
        rData = 0;
        case (strb)
            2'b00: begin
                rData[7:0]   = mem[rAddr+0];  // byte
                rData[15:8]  = 0;
                rData[23:16] = 0;
                rData[31:24] = 0;
            end
            2'b01: begin  // half
                rData[7:0]   = mem[rAddr+0];  // half
                rData[15:8]  = mem[rAddr+1];
                rData[23:16] = 0;
                rData[31:24] = 0;
            end
            2'b10: begin  // word
                rData[7:0]   = mem[rAddr+0];  // word
                rData[15:8]  = mem[rAddr+1];
                rData[23:16] = mem[rAddr+2];
                rData[31:24] = mem[rAddr+3];
            end
        endcase
    end
endmodule
