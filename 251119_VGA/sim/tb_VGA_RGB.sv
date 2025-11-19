module tb_VGA_RGB ();
    logic clk;
    logic reset;
    logic [3:0] r_sw;
    logic [3:0] g_sw;
    logic [3:0] b_sw;
    logic h_sync;
    logic v_sync;
    logic [3:0] r_port;
    logic [3:0] g_port;
    logic [3:0] b_port;

    VGA_RGB_Controller dut (.*);

    always #5 clk = ~clk;

    initial begin
        clk = 0; reset = 1;
        #10; reset = 0;
        repeat (4) @(posedge clk);
        r_sw = 4'hF; g_sw = 4'h0; b_sw = 4'h0; // Red
    end
    
endmodule