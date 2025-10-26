`timescale 1ns / 1ps

module RAM (
    // input  logic        clk,
    // input  logic [ 2:0] strb,
    // input  logic        we,
    // input  logic [ 7:0] addr,
    // input  logic [31:0] wData,
    // output logic [31:0] rData
    input logic PCLK,
    // APB Interface Signals
    input logic [2:0] strb,
    input logic [11:0] PADDR,
    input logic PWRITE,
    input logic PSEL,
    input  logic PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic PREADY
);

    logic [31:0] mem [0:2**12-1]; // 0x000 ~ 0xFFF

    always_ff @( posedge PCLK ) begin
        PREADY <= 1'b0;
        if (PSEL && PENABLE) begin
            PREADY <= 1'b1;
            if (PWRITE) mem[PADDR[11:2]] <= PWDATA;
            else PRDATA <= mem[PADDR[11:2]];
        end
    end
    /*
    logic [7:0] mem[0:2**8-1];

    always_ff @(posedge clk) begin
        if (PSEL && PENABLE) begin
            PREADY <= 1'b1;
            if (PWRITE) begin
                mem[PADDR] <= mem[PADDR];
                case (strb)
                    3'b000: begin // byte
                        mem[PADDR+0] <= PWDATA[7:0];
                    end
                    3'b001: begin  // half
                        mem[PADDR+0] <= PWDATA[7:0];
                        mem[PADDR+1] <= PWDATA[15:8];
                    end
                    3'b010: begin  // word
                        mem[PADDR+0] <= PWDATA[7:0];
                        mem[PADDR+1] <= PWDATA[15:8];
                        mem[PADDR+2] <= PWDATA[23:16];
                        mem[PADDR+3] <= PWDATA[31:24];
                    end
                endcase
            end
        end
    end

    always_comb begin
        PRDATA = 0;
        case (strb)
            3'b000: begin // LB
                PRDATA[7:0]   = mem[PADDR+0];
                PRDATA[31:8]  = {24{mem[PADDR][7]}};
            end
            3'b001: begin  // LH
                PRDATA[7:0]   = mem[PADDR+0];
                PRDATA[15:8]  = mem[PADDR+1];
                PRDATA[31:16] = {16{mem[PADDR+1][7]}};
            end
            3'b010: begin  // LW
                PRDATA[7:0]   = mem[PADDR+0];
                PRDATA[15:8]  = mem[PADDR+1];
                PRDATA[23:16] = mem[PADDR+2];
                PRDATA[31:24] = mem[PADDR+3];
            end
            3'b100: begin // LBU
                PRDATA[7:0]   = mem[PADDR+0];
                PRDATA[31:8]  = 0;
            end
            3'b101: begin  // LHU
                PRDATA[7:0]   = mem[PADDR+0];
                PRDATA[15:8]  = mem[PADDR+1];
                PRDATA[31:16] = 0;
            end
        endcase
    end
    */
endmodule
