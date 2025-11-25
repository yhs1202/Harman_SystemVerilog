module ascii_mapper (
    input  logic        DE,
    input  logic [7:0]  gray,
    output logic [7:0]  ascii_out
);

  always_comb begin
    if (!DE) ascii_out = 8'd32; // space
    else begin
      case (gray)
        8'd0   : ascii_out = "@";
        8'd1   : ascii_out = "@";
        default: begin
          if      (gray <  26) ascii_out = "@";
          else if (gray <  52) ascii_out = "%";
          else if (gray <  78) ascii_out = "#";
          else if (gray < 103) ascii_out = "*";
          else if (gray < 129) ascii_out = "+";
          else if (gray < 154) ascii_out = "=";
          else if (gray < 180) ascii_out = "-";
          else if (gray < 205) ascii_out = ":";
          else if (gray < 231) ascii_out = ".";
          else                 ascii_out = " ";
        end
      endcase
    end
  end
endmodule
