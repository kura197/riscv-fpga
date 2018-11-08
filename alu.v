module ALU #(parameter WIDTH = 32)(
	input clk,
	input  [WIDTH-1:0]	SrcA, SrcB,
	input  [3:0]	ALUControl,
	input  MULH,
	output reg InstrFault,
	output reg [WIDTH-1:0]	ALUResult
);

`include "alu.h"
wire [31:0] div,rem;
wire [63:0] mul;
wire [31:0] mulH = mul[63:32];
wire [31:0] mulL = mul[31:0];
//wire [63:0] multi = SrcA * SrcB;

always @* begin
	InstrFault = 1'b0;
	case(ALUControl)
		AND:ALUResult = SrcA & SrcB;
		SUB:ALUResult = SrcA - SrcB;
		ADD:ALUResult = SrcA + SrcB;
		XOR:ALUResult = SrcA ^ SrcB;
		OR:ALUResult = SrcA | SrcB;
		SLT:ALUResult = $signed(SrcA) < $signed(SrcB);
		SLTU:ALUResult = SrcA < SrcB;
		TEST:ALUResult = SrcA == SrcB;
		SLL:ALUResult = SrcA << SrcB;
		SRL:ALUResult = SrcA >> SrcB;
		SRA:ALUResult = $signed(SrcA) >>> SrcB;
		CLR:ALUResult = ~SrcA & SrcB;
		//MUL:ALUResult = (MULH) ? multi[63:32] : multi[31:0];
		//DIV:ALUResult = SrcA / SrcB;
		//REM:ALUResult = SrcA % SrcB;
		MUL:ALUResult = (MULH) ? mulH : mulL;
		DIV:ALUResult = div;
		REM:ALUResult = rem;
		default:
			begin
				ALUResult = 0;
				InstrFault = 1'b1;
			end
	endcase
end

div	div_inst (
	.clock ( clk ),
	.denom ( SrcB ),
	.numer ( SrcA ),
	.quotient ( div ),
	.remain ( rem )
	);

mul	mul_inst (
	.dataa ( SrcA ),
	.datab ( SrcB ),
	.result ( mul )
	);

endmodule
