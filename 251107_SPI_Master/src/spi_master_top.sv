`timescale 1ns/1ps
module spi_master_top (
    // global signals
    input logic clk,
    input logic rst,

    // user inputs for upcounter controller
    input logic btn_runstop,
    input logic btn_clear,


    // SPI signals
    output logic SCLK,
    output logic MOSI,
    input logic MISO, // not used
    output logic SS_n // Slave Select (active low)
);

    // internal signals
    logic start;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic tx_ready;
    logic done;


    // Instantiate SPI Master
    spi_master u_spi_master (.*);
    // Instantiate upcounter controller
    upcounter_controller u_upcounter_controller (.*);
endmodule


// 10000 counter and send count to SPI master
module upcounter_controller (
    input logic clk,
    input logic rst,
    input logic btn_runstop,
    input logic btn_clear,

    input logic tx_ready,
    input logic done,
    output logic start,
    output logic [7:0] tx_data,
    output logic SS_n
);
    // logic lsb_done, msb_done;
    // assign done = lsb_done & msb_done;


    // import Upcounter logic from my counter_top module
    logic [13:0] counter;
    counter_top U_COUNTER_TOP (
        .clk (clk),
        .rst (rst),
        .mode (1'b0), // up counter
        .enable (btn_runstop),
        .clear (btn_clear),
        .counter (counter)
    );

    // SPI control logic

    // state encoding
    typedef enum logic [2:0] {
        IDLE,
        SEND_LSB,
        SEND_MSB,
        WAIT_LSB_DONE,
        WAIT_MSB_DONE
    } state_t;

    state_t state_reg, state_next;
    wire [7:0] lsb8 = counter[7:0];
    wire [7:0] msb8 = {2'b0, counter[13:8]};

    always_ff @( posedge clk, posedge rst ) begin : state_ff
        if (rst) begin
            state_reg <= IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    always_comb begin : state_next_logic
        // Default assignments
        state_next = state_reg;
        start = 1'b0;
        tx_data = 8'd0;
        SS_n = 1'b1;

        case (state_reg)
            IDLE: begin
                SS_n = 1'b1;
                if (tx_ready) begin
                    state_next = SEND_LSB;
                end
            end

            SEND_LSB: begin
                SS_n = 1'b0; // Activate slave
                tx_data = lsb8;
                start = 1'b1;
                state_next = WAIT_LSB_DONE;
            end

            WAIT_LSB_DONE: begin
                SS_n = 1'b0;
                if (done) begin // LSB done
                    state_next = SEND_MSB;
                end
            end

            SEND_MSB: begin
                SS_n = 1'b0; // Activate slave
                tx_data = msb8;
                start = 1'b1;
                state_next = WAIT_MSB_DONE;
            end

            WAIT_MSB_DONE: begin
                SS_n = 1'b0;
                if (done) begin // MSB done
                    state_next = IDLE;
                end
            end
        endcase
    end
endmodule