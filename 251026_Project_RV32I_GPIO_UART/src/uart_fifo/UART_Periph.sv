`timescale 1ns / 1ps
module UART_Periph (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [2:0]  PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        TX,
    input  logic        RX
);

    logic [7:0] tx_data, rx_data;
    logic tx_wr, rx_rd;
    logic tx_empty, tx_busy, rx_valid;

    // APB Slave Interface
    APB_SlaveIntf_UART u_intf (
        .PCLK, .PRESET, .PADDR, .PWRITE, .PENABLE, .PSEL,
        .PWDATA, .PRDATA, .PREADY,
        .tx_data, .tx_wr, .tx_empty, .tx_busy, 
        .rx_data, .rx_rd, .rx_valid
    );

    // UART Core
    // UART_FIFO_loopback u_core (
    //     .clk(PCLK),
    //     .rst(PRESET),
    //     // .tx_fifo_data(tx_data),
    //     .tx_w_en(tx_wr),
    //     .tx_fifo_empty(tx_empty),
    //     .tx_busy(tx_busy),
    //     .tx(TX),

    //     .fifo_data(rx_data),
    //     .rx_r_en(rx_rd),
    //     .rx_done(rx_valid),
    //     .rx(RX)
    // );
    UART_CORE u_core (
        .clk(PCLK),
        .rst(PRESET),
        .tx_data(tx_data),
        .tx_wr(tx_wr),
        .tx_empty(tx_empty),
        .tx_busy(tx_busy),
        .TX(TX),

        .rx_data(rx_data),
        .rx_rd(rx_rd),
        .rx_valid(rx_valid),
        .RX(RX)
    );
endmodule


// APB Slave Interface for UART Peripheral
// - 0x00 : TX DATA (Write Only)
// - 0x04 : RX DATA (Read Only)
// - 0x08 : STATUS  (Read Only)
module APB_SlaveIntf_UART (
    // global
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface
    input  logic [2:0]  PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // UART Interface
    output logic [7:0]  tx_data,    // write data from CPU
    output logic        tx_wr,      // TX FIFO write enable
    input  logic        tx_empty,   // TX FIFO empty flag
    input  logic        tx_busy,    // TX currently transmitting

    input  logic [7:0]  rx_data,    // received data from UART
    output logic        rx_rd,      // RX FIFO read enable
    input  logic        rx_valid   // RX FIFO data valid

);

    // Internal registers
    logic [31:0] slv_reg0; // TX DATA
    logic [31:0] slv_reg1; // RX DATA
    logic [31:0] slv_reg2; // STATUS

    // Default output assignments
    assign tx_data = slv_reg0[7:0];


    // APB read/write operation
    always_ff @(posedge PCLK or posedge PRESET) begin
        if (PRESET) begin
            slv_reg0 <= 32'b0;
            slv_reg1 <= 32'b0;
            PREADY   <= 1'b0;
            tx_wr    <= 1'b0;
            rx_rd    <= 1'b0;
        end else begin
            PREADY <= 1'b0;
            tx_wr  <= 1'b0;
            rx_rd  <= 1'b0;

            if (PSEL && PENABLE) begin
                $display("UART APB ACCESS: ADDR=%h, PWRITE=%b, PWDATA=%h", PADDR, PWRITE, PWDATA);
                PREADY <= 1'b1;
                // Write operations
                if (PWRITE) begin
                    case (PADDR[2:1])
                        2'b00: begin // TXDATA
                            slv_reg0 <= PWDATA;
                            tx_wr    <= 1'b1; // trigger TX FIFO write
                        end
                        default: ;
                    endcase
                end
                // Read operations
                else begin
                    case (PADDR[2:1])
                        2'b00: PRDATA <= 32'b0; // TXDATA: write only
                        2'b01: begin // RXDATA
                            $display("RX DATA READ: %h", rx_data);
                            PRDATA <= {24'b0, rx_data};
                            rx_rd  <= 1'b1; // pop from RX FIFO
                        end
                        2'b10: begin // STATUS
                            slv_reg2[0] <= tx_empty; // TX empty
                            slv_reg2[1] <= tx_busy;  // TX busy
                            slv_reg2[2] <= rx_valid; // RX valid
                            PRDATA <= slv_reg2;
                        end
                        default: PRDATA <= 32'h0;
                    endcase
                end
            end
        end
    end
endmodule

