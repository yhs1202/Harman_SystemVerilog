`timescale 1ns/1ps
module AXI_Lite_Slave (
    // Global signals
    input logic ACLK,
    input logic ARESETn,

    /* WRITE Transaction */
    // AW Channel
    input logic [3:0] AWADDR,
    input logic AWVALID,
    output logic AWREADY,
    // W Channel
    input logic [31:0] WDATA,
    input logic WVALID,
    output logic WREADY,
    // B Channel
    output logic [1:0] BRESP,
    output logic BVALID,
    input logic BREADY,

    /* READ Transaction */
    // AR Channel
    input logic [3:0] ARADDR,
    input logic ARVALID,
    output logic ARREADY,
    // R Channel
    output logic [31:0] RDATA,
    output logic RVALID,
    input logic RREADY,
    output logic [1:0] RRESP
);

    // Slave Registers
    logic [31:0] slv_reg0, slv_reg1, slv_reg2, slv_reg3;
    logic [3:0] awaddr_reg, awaddr_next;
    logic [3:0] araddr_reg, araddr_next;

    /* WRITE Transaction */
    // AW Channel
    typedef enum { 
        AW_IDLE_S,
        AW_READY_S
    } aw_state_e;

    aw_state_e aw_state, aw_state_next;

    always_ff @(posedge ACLK) begin : AW_ff
        if (!ARESETn) begin // Synchronous reset
            aw_state <= AW_IDLE_S;
            awaddr_reg <= 0;
        end else begin
            aw_state <= aw_state_next;
            awaddr_reg <= awaddr_next;
        end
    end

    always_comb begin : AW_comb
        aw_state_next = aw_state;
        awaddr_next = awaddr_reg;
        AWREADY = 1'b0;
        case (aw_state)
            AW_IDLE_S: begin
                if (AWVALID) begin
                    aw_state_next = AW_READY_S;
                    awaddr_next = AWADDR;
                end
            end
            AW_READY_S: begin
                AWREADY = 1'b1;
                if (AWVALID & AWREADY) begin
                    aw_state_next = AW_IDLE_S;
                end
            end
        endcase
    end


    // W Channel
    typedef enum { 
        W_IDLE_S,
        W_READY_S
    } w_state_e;

    w_state_e w_state, w_state_next;

    always_ff @(posedge ACLK) begin : W_ff
        if (!ARESETn) begin // Synchronous reset
            w_state <= W_IDLE_S;
        end else begin
            w_state <= w_state_next;
        end
    end

    always_comb begin : W_comb
        w_state_next = w_state;
        WREADY = 1'b0;
        case (w_state)
            W_IDLE_S: begin
                WREADY = 1'b0;
                if (AWVALID) begin
                    w_state_next = W_READY_S;
                end
            end
            W_READY_S: begin
                WREADY = 1'b1;
                if (WVALID) begin
                    w_state_next = W_IDLE_S;
                    // Write to slave registers
                    case (awaddr_reg[3:2])
                        2'd0: slv_reg0 = WDATA;
                        2'd1: slv_reg1 = WDATA;
                        2'd2: slv_reg2 = WDATA;
                        2'd3: slv_reg3 = WDATA;
                    endcase
                end
            end
        endcase
    end


    // B Channel
    typedef enum { 
        B_IDLE_S,
        B_VALID_S
    } b_state_e;

    b_state_e b_state, b_state_next;

    always_ff @(posedge ACLK) begin : B_ff
        if (!ARESETn) begin // Synchronous reset
            b_state <= B_IDLE_S;
        end else begin
            b_state <= b_state_next;
        end
    end

    always_comb begin : B_comb
        b_state_next = b_state;
        BVALID = 1'b0;
        BRESP = 2'b00; // OKAY response
        case (b_state)
            B_IDLE_S: begin
                BVALID = 1'b0;
                if (WVALID & WREADY) begin
                    b_state_next = B_VALID_S;
                end
            end
            B_VALID_S: begin
                BVALID = 1'b1;
                BRESP = 2'b00; // OKAY response
                // if (BREADY) begin
                    b_state_next = B_IDLE_S;
                // end
            end
        endcase
    end
    
    /* READ Transaction */
    // AR Channel
    typedef enum { 
        AR_IDLE_S,
        AR_READY_S
    } ar_state_e;

    ar_state_e ar_state, ar_state_next;

    always_ff @(posedge ACLK) begin : AR_ff
        if (!ARESETn) begin // Synchronous reset
            ar_state <= AR_IDLE_S;
        end else begin
            ar_state <= ar_state_next;
        end
    end

    always_comb begin : AR_comb
        ar_state_next = ar_state;
        ARREADY = 1'b0;
        araddr_reg = ARADDR;
        case (ar_state)
            AR_IDLE_S: begin
                if (ARVALID) begin
                    ar_state_next = AR_READY_S;
                end
            end
            AR_READY_S: begin
                ARREADY = 1'b1;
                araddr_reg = ARADDR;
                ar_state_next = AR_IDLE_S;
            end
        endcase
    end


    // R Channel
    typedef enum { 
        R_IDLE_S,
        R_VALID_S
    } r_state_e;

    r_state_e r_state, r_state_next;

    always_ff @(posedge ACLK) begin : R_ff
        if (!ARESETn) begin // Synchronous reset
            r_state <= R_IDLE_S;
        end else begin
            r_state <= r_state_next;
        end
    end

    always_comb begin : R_comb
        r_state_next = r_state;
        RVALID = 1'b0;
        RRESP = 2'b00; // OKAY response
        case (r_state)
            R_IDLE_S: begin
                if (ARVALID & ARREADY) begin
                    r_state_next = R_VALID_S;
                end
            end
            R_VALID_S: begin
                RVALID = 1'b1;
                // Read from slave registers
                case (araddr_reg[3:2])
                    2'd0: RDATA = slv_reg0;
                    2'd1: RDATA = slv_reg1;
                    2'd2: RDATA = slv_reg2;
                    2'd3: RDATA = slv_reg3;
                endcase
                if (RREADY) begin
                    r_state_next = R_IDLE_S;
                end
            end
        endcase
    end
endmodule