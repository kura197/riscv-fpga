module CONTROLLER(
	input clk,reset,
	input [6:0] Opcode,
	input [2:0] Funct3,
	input [6:0] Funct7,
	output WenPC,
	output WenInstr,
	output WenRegfile,
	output WenMem,
	output WenCSR,
	output WenRS2,
	output AddrSrcCont,
	output [2:0] ALUSrcACont,
	output [2:0] ALUSrcBCont,
	output [2:0] ImmCont,
	output [3:0] ALUCont,
	output [1:0] ResCont,
	input ALUFlag,
	output [2:0] MemStrb,
	input [1:0] RunLevel,
	input DataValid,
	output read_req,
	output MULH,
	output ECALL,
	output MRET,
	output INTR,
	input halt,
	input enintr
);

wire [2:0] decode_type;
assign ImmCont = decode_type;
TYPE_DECODER type_decoder(Opcode,Funct3,decode_type);

CONT_DECODER cont_decoder(
	.clk(clk),
	.reset(reset),
	.decode_type(decode_type),
	.Funct7(Funct7),
	.Funct3(Funct3),
	.Opcode(Opcode),
	.WenPC(WenPC),
	.WenInstr(WenInstr),
	.WenRegfile(WenRegfile),
	.WenMem(WenMem),
	.WenCSR(WenCSR),
	.WenRS2(WenRS2),
	.AddrSrcCont(AddrSrcCont),
	.ALUSrcACont(ALUSrcACont),
	.ALUSrcBCont(ALUSrcBCont),
	.ALUCont(ALUCont),
	.ResCont(ResCont),
	.ALUFlag(ALUFlag),
	.MemStrb(MemStrb),
	.RunLevel(RunLevel),
	.DataValid(DataValid),
	.ReadReq(read_req),
	.MULH(MULH),
	.ECALL(ECALL),
	.MRET(MRET),
	.INTR(INTR),
	.halt(halt),
	.enintr(enintr)
);

endmodule
