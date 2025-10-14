`define ADD 4'b0000
`define SUB 4'b1000
`define SLL 4'b0001
`define SRL 4'b0101
`define SRA 4'b1101
`define SLT 4'b0010
`define SLTU 4'b0011
`define XOR 4'b0100
`define OR 4'b0110
`define AND 4'b0111

`define SLLI 4'b0001
`define SRLI 4'b0101
`define SRAI 4'b1101

`define OP_TYPE_R 7'b011_0011
`define OP_TYPE_I 7'b001_0011

`define OP_TYPE_S		7'b010_0011     // S-type
`define OP_TYPE_I_LOAD	7'b000_0011     // I-type load

`define OP_TYPE_I_JALR	7'b110_0111     // I-type JALR
`define OP_TYPE_B		7'b110_0011     // B-type
`define OP_TYPE_U_LUI	7'b011_0111     // U-type LUI
`define OP_TYPE_U_AUIPC	7'b001_0111     // U-type AUIPC
`define OP_TYPE_J_JAL	7'b110_1111     // J-type JAL
