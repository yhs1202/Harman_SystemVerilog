`timescale 1ns / 1ps
module UART_Periph (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [3:0]  PADDR,
    input  logic [31:0] PWDATA,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    // External Port
    output logic        tx,
    input  logic        rx
);

    logic [7:0] tx_data, rx_data;
    logic tx_we, rx_re;
    logic rx_full, tx_empty, tx_full, rx_empty; // status signals

    // APB Slave Interface
    APB_SlaveIntf_UART u_intf (
        .*,
        // UART Internal Signals
        .USR ({rx_full, tx_empty, tx_full, rx_empty}),
        .UWD (tx_data),
        .URD (rx_data),
        .tx_we (tx_we),
        .rx_re (rx_re)
    );

    // UART/FIFO Core
    UART_FIFO_CORE U_UART_FIFO_CORE (
        .clk (PCLK),
        .rst (PRESET),

        // Status Signals
        .rx_full (rx_full),
        .tx_empty (tx_empty),
        .tx_full (tx_full),
        .rx_empty (rx_empty),

        // RX Interface
        .rx (rx),
        .rx_data (rx_data),
        .rx_re (rx_re),

        // TX Interface
        .tx (tx),
        .tx_data (tx_data),
        .tx_we (tx_we)
    );

endmodule


// APB Slave Interface for UART Peripheral
// - 0x00 : USR (UART_STATUS, Read Only)
// - 0x04 : UWD (UART_WRITE_DATA, Write Only)
// - 0x08 : URD (UART_READ_DATA, Read Only)
// - 0x0C : Reserved (UART_WRITE_DATA_Next, No Access)
module APB_SlaveIntf_UART (
    // global signals
    input  logic        PCLK,
    input  logic        PRESET,
    // APB Interface Signals
    input  logic [3:0]  PADDR,
    input  logic        PWRITE,
    input  logic        PENABLE,
    input  logic        PSEL,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,

    // UART Internal Signals
    input logic [3:0] USR,      // UART Status Register {rx_fifo_full, tx_fifo_empty, tx_fifo_full, rx_fifo_empty}
    output logic [7:0] UWD,     // UART Write Data (tx_wdata)
    input  logic [7:0] URD,     // UART Read Data (rx_rdata) 
    output logic tx_we,         // UART TX Write Enable
    output logic rx_re          // UART RX Read Enable

);

    // Internal registers
    logic [31:0] slv_reg0; // USR (STATUS, Read only for CPU)
    logic [31:0] slv_reg1; // UWD (WRITE DATA, Write only for CPU)
    logic [31:0] slv_reg2; // URD (READ DATA, Read only for CPU)
    logic [31:0] slv_reg3; // UWD_next (tx_data_next, No Access)

    logic tx_wr_reg, tx_wr_next;
    logic rx_rd_reg, rx_rd_next;
    logic [31:0] prdata_reg, prdata_next;
    logic pready_reg, pready_next;

    assign tx_we = tx_wr_reg;
    assign rx_re = rx_rd_reg;
    assign slv_reg0[3:0] = USR; // UART Status Register
    assign UWD = slv_reg1[7:0];
    assign slv_reg2[7:0] = URD; // UART Read Data Register

    assign PRDATA = prdata_reg;
    assign PREADY = pready_reg;

    typedef enum {
        IDLE,
        READ_RXDATA,
        WRITE_TXDATA
    } state_t;

    state_t state_reg, state_next;

    // State Transition
    always_ff @(posedge PCLK or posedge PRESET) begin : state_ff
        if (PRESET) begin    
            state_reg <= IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    // Output Signals
    always_ff @(posedge PCLK, posedge PRESET) begin : output_ff
        if (PRESET) begin
            slv_reg0[31:4] <= 28'b0;
            slv_reg1 <= 32'b0;
            slv_reg2[31:8] <= 24'b0;
            prdata_reg <= 32'bx;
            pready_reg <= 1'b0;
            tx_wr_reg <= 1'b0;
            rx_rd_reg <= 1'b0;
        end else begin
            slv_reg1 <= slv_reg3;
            prdata_reg <= prdata_next;
            pready_reg <= pready_next;
            tx_wr_reg <= tx_wr_next;
            rx_rd_reg <= rx_rd_next;
        end
    end
    

    // APB read/write operation
    always_comb begin : apb_rw_comb
        // Default assignments
        state_next = state_reg;

        slv_reg3 = slv_reg1; // UWD_next = UWD

        tx_wr_next = 1'b0;
        rx_rd_next = 1'b0;

        prdata_next = prdata_reg;
        pready_next = pready_reg;

        case (state_reg) 
            IDLE: begin
                pready_next = 1'b0;
                if (PSEL && PENABLE) begin
                    if (PWRITE) begin // Write Operation
                        state_next = WRITE_TXDATA;
                        pready_next = 1'b1;
                        case (PADDR[3:2])
                            2'd1: begin // UWD
                                slv_reg3 = PWDATA;
                                tx_wr_next = 1'b1;
                            end
                            default: ; // No operation for other addresses
                        endcase
                    end else begin // Read Operation
                            state_next = READ_RXDATA;
                            pready_next = 1'b1;
                            case (PADDR[3:2])
                                2'd0: prdata_next = slv_reg0; // STATUS
                                2'd1: prdata_next = slv_reg1; // UWD
                                2'd2: begin
                                    prdata_next = slv_reg2; // URD
                                    rx_rd_next = 1'b1;
                                end
                                2'd3: ;    // Reserved
                        endcase
                    end
                end
            end

            READ_RXDATA: begin
                pready_next = 1'b0;
                state_next  = IDLE;
            end

            WRITE_TXDATA: begin
                state_next  = IDLE;
                pready_next = 1'b0;
            end
        endcase
    end
endmodule
