module EXTEND(
	input [31:0] Instr,
	input [2:0] ImmSrc,
	output reg [31:0] ExtImm
);

`include "type.h"

always @*
	case(ImmSrc)
		//R(for sll)
		Rtype:ExtImm <= {27'h0, Instr[24:20]};
		//I
		Itype:ExtImm <= {{21{Instr[31]}}, Instr[30:25], Instr[24:21], Instr[20]};
		//S
		Stype:ExtImm <= {{21{Instr[31]}}, Instr[30:25], Instr[11:8], Instr[7]};
		//B
		Btype:ExtImm <= {{20{Instr[31]}}, Instr[7], Instr[30:25], Instr[11:8], 1'b0};
		//U
		Utype:ExtImm <= {Instr[31], Instr[30:20], Instr[19:12], 12'h0};
		//J
		Jtype:ExtImm <= {{12{Instr[31]}}, Instr[19:12], Instr[20], Instr[30:25],Instr[24:21],1'b0};
		//SYSTEM
		SYSTEM:ExtImm <= {27'h0, Instr[19:15]};
		default:ExtImm <= 32'b0;
	endcase

endmodule
