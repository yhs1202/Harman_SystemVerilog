`timescale 1ns / 1ps
module sum_1to10_with_regfile_datapath (
    input logic clk,
    input logic rst,
    input logic R1SrcSel,
    input logic [1:0] r_addr_0,
    input logic [1:0] r_addr_1,
    input logic w_en,
    input logic [1:0] w_addr,
    input logic OutLoad,

    output logic iLe10,
    output logic [7:0] out
);

    logic [7:0] r_data_0;
    logic [7:0] r_data_1;

    // logic [7:0] w_data;
    logic [7:0] adder_b;
    logic [7:0] adder_out;

    // Instantiate modules
    // mux_2x1 U_MUX_SUMSRC (
    //     .sel (R1SrcSel),
    //     .in0 (adder_out),
    //     .in1 (8'b1),
    //     .out (w_data)
    // );

    register_file_4 U_REGFILE (
        .clk (clk),
        .r_addr_0 (r_addr_0),
        .r_addr_1 (r_addr_1),
        .w_en (w_en),
        .w_addr (w_addr),
        .w_data (adder_out),
        .r_data_0 (r_data_0),
        .r_data_1 (r_data_1)
    );

    // mux_2x1 U_MUX_ISRC (
    //     .sel (iSrcSel),
    //     .in0 (8'b0),
    //     .in1 (adder_out),
    //     .out (i_mux_out)
    // );

    // Register U_SUM_REG (
    //     .*,
    //     .Load_en (sumLoad),
    //     .d (sum_mux_out),
    //     .q (sum_reg_out)
    // );

    // Register U_I_REG (
    //     .*,
    //     .Load_en (iLoad),
    //     .d (i_mux_out),
    //     .q (i_reg_out)
    // );

    Comparator U_COMPARATOR (
        .a(adder_b), // i_reg_out
        .b(8'd10),
        .sle(iLe10)
    );

    mux_2x1 U_MUX_ADDERSRC (
        .sel (R1SrcSel),
        .in0 (r_data_1), // i_reg_out
        .in1 (8'b1),
        .out (adder_b)
    );


    Adder U_ADDER (
        .a (r_data_0), // sum_reg_out
        .b (adder_b), // i_reg_out (r_data_1) or 1
        .sum (adder_out)
    );

    Register U_OUTREG (
        .*,
        .Load_en (OutLoad),
        .d (r_data_0), // sum_reg_out
        .q (out)
    );


    
endmodule

// 4byte RegisterFile 
module register_file_4 (
    input logic clk,
    input logic [1:0] r_addr_0,
    input logic [1:0] r_addr_1,
    input logic w_en,
    input logic [1:0] w_addr,
    input logic [7:0] w_data,

    output logic [7:0] r_data_0,
    output logic [7:0] r_data_1
);
    logic [7:0] mem [0:3];
    
    assign mem[0] = 8'b0; // $0 is always 0

    assign r_data_0 = mem[r_addr_0];
    assign r_data_1 = mem[r_addr_1];

    always_ff @( posedge clk ) begin
        if (w_en && (w_addr != 2'b00)) begin
            mem[w_addr] <= w_data;
        end
    end
endmodule


// 2x1 MUX
module mux_2x1 (
    input logic sel,
    input logic [7:0] in0,
    input logic [7:0] in1,
    output logic [7:0] out
);
    always_comb begin
        out = 8'b0;
        if (sel) out = in1;
        else out = in0;
    end

endmodule


// Register with load enable
module Register (
    input logic clk,
    input logic rst,
    input logic Load_en,
    input logic [7:0] d,
    output logic [7:0] q
);

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            q <= 0;
        end else begin
            if (Load_en) begin
                q <= d;
            end
        end
    end
endmodule


// Comparator for two 8-bit numbers
module Comparator (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic sle
);
    assign sle = a <= b;

endmodule


// adder for two 8-bit numbers
module Adder (
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] sum
);
    assign sum = a + b;

endmodule