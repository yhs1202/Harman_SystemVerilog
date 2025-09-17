`timescale 1ns / 1ps

module dedicated_processor_counter (
    input logic clk,
    input logic rst,
    output logic [7:0] out
);

    logic AsrcSel, ALoad, OutBufSel, ALt10;

    counter_control_unit U_CONTROL_UNIT (
        .*
    );

    counter_datapath U_DATAPATH (
        .*,
        .out(out)
    );


    
endmodule