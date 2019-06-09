module TYPE_DECODER(
	input [6:0] Opcode,
	input [2:0] Funct3,
	output reg [2:0] decode_type
);
`include "type.h"

wire R = (Funct3 == 3'b001 || Funct3 == 3'b101) ? 1'b1 : 1'b0;

always @*
	if(Opcode == 7'b0101111)
		decode_type <= NOP;
	else if(Opcode == 7'b1110011)
		decode_type <= SYSTEM;
	else if(Opcode == 7'b0110011 || (Opcode == 7'b0010011 && R))
		decode_type <= Rtype;
	else if(Opcode == 7'b0000011 || Opcode == 7'b0010011 || Opcode == 7'b1100111)
		decode_type <= Itype;
	else if(Opcode == 7'b0100011)
		decode_type <= Stype;
	else if(Opcode == 7'b1100011)
		decode_type <= Btype;
	else if(Opcode == 7'b0110111 || Opcode == 7'b0010111)
		decode_type <= Utype;
	else if(Opcode == 7'b1101111)
		decode_type <= Jtype;
	else
		decode_type <= 3'bxxx;

endmodule
