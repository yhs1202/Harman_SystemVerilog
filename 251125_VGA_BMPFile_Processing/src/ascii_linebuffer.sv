module ascii_line_buffer #(
    parameter WIDTH = 640
)(
    input  logic        clk,
    input  logic        DE,           // active during pixel
    input  logic [7:0]  ascii_in,
    input  logic        line_end,     // x == WIDTH-1 conditions

    output logic [7:0]  line_buf [0:WIDTH-1],
    output logic        line_ready
);

  int index = 0;
  assign line_ready = line_end; // 1 line end

  always_ff @(posedge clk) begin
    if (!DE) index <= 0;
    else begin
      line_buf[index] <= ascii_in;
      if (index == WIDTH-1) index <= 0;
      else index <= index + 1;
    end
  end
endmodule
