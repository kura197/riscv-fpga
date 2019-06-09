module DATAPATH(
	input clk, reset,
	input [31:0] indata,
	output [31:0] addr, wrdata,
	input WenPC,
	input WenInstr,
	input WenRegfile,
	input WenCSR,
	input WenRS2,
	input AddrSrcCont,
	input [2:0] ALUSrcACont,
	input [2:0] ALUSrcBCont,
	input [2:0] ImmCont,
	input [3:0] ALUCont,
	input [1:0] ResCont,
	output [6:0] Opcode,
	output [2:0] Funct3,
	output [6:0] Funct7,
	output ALUFlag,
	output [1:0] RunLevel,
	output [31:0] satp,
	input uart_rx_recv,
    input kbd_valid,
	input ECALL,
	input MULH,
	input MRET,
	input INTR,
	output enintr,
	input [63:0] mtimecmp,
    output TLB_refresh,
	output [31:0] PC,
	output [31:0] a0
);

wire [31:0] instr;
wire [31:0] rddata;

wire [4:0] ra1,ra2,rd,wa;
wire [31:0] tmp_rs1,tmp_rs2;
wire [31:0] wd,rs1,rs2;
wire [31:0] ExtImm;

wire [31:0] tmpSrcA,tmpSrcB;
wire [31:0] SrcA,SrcB,ALURes,tmp_ALURes;
wire [31:0] next_PC;
wire InstrFault;
wire CSRFault;
wire [11:0] csra;
wire [31:0] csr;

wire [31:0] res;

FLOPENR #(32) flop_PC(clk,reset,WenPC,res,PC);
MUX2 #(32) mux_pc_res(PC,res,AddrSrcCont,addr);

assign wrdata = rs2;
FLOPENR #(32) flop_instr(clk,reset,WenInstr,indata,instr);
FLOPR #(32) flop_rddata(clk,reset,indata,rddata);
assign Opcode = instr[6:0];
assign Funct3 = instr[14:12];
assign Funct7 = instr[31:25];

assign ra1 = instr[19:15];
assign ra2 = instr[24:20];
assign rd = instr[11:7];
assign csra = instr[31:20];

assign wd = res;
assign wa = rd;
REGFILE #(32'd2048) regfile(
	.clk(clk),
	.reset(reset),
	.we(WenRegfile),
	.ra1(ra1),
	.ra2(ra2),
	.wa(wa),
	.wd(wd),
	.rs1(tmp_rs1),
	.rs2(tmp_rs2),
	.a0(a0)
);
CSRFILE csrfile(clk,reset,csra,WenCSR,RunLevel,res,csr,satp,mtimecmp,ECALL,MRET,INTR,uart_rx_recv,kbd_valid,enintr,TLB_refresh,CSRFault);
FLOPR #(32) flop_rs1(clk,reset,tmp_rs1,rs1);
FLOPENR #(32) flop_rs2(clk,reset,WenRS2,tmp_rs2,rs2);
EXTEND extend(instr,ImmCont,ExtImm);

MUX8 #(32) mux_rs1_pc_res_zero_extimm(rs1,PC,res,32'b0,ExtImm,32'hx,32'hx,32'hx,ALUSrcACont,tmpSrcA);
MUX8 #(32) mux_rs2_extimm_4_m4_zero_csr(rs2,ExtImm,32'h4,32'hfffffffc,32'h0,csr,32'hx,32'hx,ALUSrcBCont,tmpSrcB);

FLOPR #(32) flop_srcA(clk,reset,tmpSrcA,SrcA);
FLOPR #(32) flop_srcB(clk,reset,tmpSrcB,SrcB);
ALU #(32) alu(clk,SrcA,SrcB,ALUCont,MULH,InstrFault,tmp_ALURes);
FLOPR #(32) flop_alu(clk,reset,tmp_ALURes,ALURes);
//assign ALUFlag = tmp_ALURes[0];
FLOPR #(1) flop_aluflag(clk,reset,tmp_ALURes[0],ALUFlag);

//assign next_PC = tmp_ALURes;
MUX4 #(32) mux_alu_nextPC_rddata_PC(ALURes,32'hz,rddata,PC,ResCont,res);

endmodule
