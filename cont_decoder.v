module CONT_DECODER(
	input clk,reset,
	input [2:0] decode_type,
	input [6:0] Funct7,
	input [2:0] Funct3,
	input [6:0] Opcode,
	output reg WenPC,
	output reg WenInstr,
	output reg WenRegfile,
	output reg WenMem,
	output reg WenCSR,
	output reg WenRS2,
	output reg AddrSrcCont,
	output reg [2:0] ALUSrcACont,
	output reg [2:0] ALUSrcBCont,
	output reg [3:0] ALUCont,
	output reg [1:0] ResCont,
	input ALUFlag,
	output reg [2:0] MemStrb,
	input [1:0] RunLevel,
	input DataValid,
	output ReadReq,
	output reg MULH,
	output reg ECALL,
	output reg MRET,
	output reg INTR,
	input halt,
	input enintr
);

`include "mux.h"
`include "alu.h"
`include "type.h"
`include "opcode.h"

localparam Fetch = 0;
localparam Decode = 1;
localparam RI0 = 2;
localparam I0 = 3;
localparam S0 = 4;
localparam B0 = 5;
localparam R0 = 6;
localparam A0 = 7;
localparam WrReg = 8;
localparam S1 = 9;
localparam I1 = 10;
localparam I2 = 11;
localparam LUI0 = 12;
localparam AUIPC0 = 13;
localparam JAL0 = 14;
localparam JALR0 = 15;
localparam SYSTEM0 = 16;
localparam AUIPC1 = 17;
localparam WrPC0 = 18;
localparam WrPC1 = 19;
localparam B1 = 20;
localparam B2 = 21;
localparam Error = 22;
localparam A1 = 23;
localparam A2 = 24;
localparam SYSTEM1 = 25;
localparam SYSTEM2 = 26;
localparam INC_PC0 = 27;
localparam INC_PC1 = 28;
localparam RI1 = 29;
localparam S2 = 30;
localparam I3 = 31;
localparam LUI1 = 32;
localparam AUIPC2 = 33;
localparam JAL1 = 34;
localparam WrPC2 = 35;
localparam A3 = 36;
localparam B3 = 37;
localparam B4 = 38;
localparam SYSTEM3 = 39;
localparam SYSTEM4 = 40;
localparam JALR1 = 41;
localparam AUIPC3 = 42;
localparam A4 = 43;
localparam ECALL0 = 44;
localparam ECALL1 = 45;
localparam ECALL2 = 46;
localparam ECALL3 = 47;
localparam MRET0 = 48;
localparam MRET1 = 49;
localparam INTR0 = 50;

reg [5:0] state;
wire clk_rev = ~clk;

wire [5:0] state_debug;
reg [5:0] now_state;
reg read_req;
reg [3:0] div_cnt;
//EDGE_TO_PULSE rdreq(clk, read_req, ReadReq);
assign ReadReq = read_req;
//debug
CONT_STATE_DEBUG debug(state,state_debug);
always @(posedge clk_rev)
	now_state <= state;

always @(posedge clk_rev, posedge reset) begin
	if(reset) begin
		state <= Fetch;
		read_req <= 1'b0;
		WenMem <= 1'b0;
		MULH <= 1'b0;
		ECALL <= 1'b0;
		MRET <= 1'b0;
		INTR <= 1'b0;
		div_cnt <= 4'h0;
	end
	else if(~halt) begin
		case(state)
			Fetch:begin
				state <= (~enintr) ? INC_PC0 : INTR0;
				MemStrb <= 3'b010;
				WenInstr <= 1'b0;
				WenMem <= 1'b0;
				WenRegfile <= 1'b0;
				WenPC <= 1'b0;
				WenCSR <= 1'b0;
				WenRS2 <= 1'b1;
				AddrSrcCont <= pc_addr;
				read_req <= 1'b0;
				ALUSrcACont <= pc_inc;
				ALUSrcBCont <= imm_4;
			end
			INC_PC0:begin
				state <= (DataValid) ? INC_PC1 : INC_PC0;
				ALUCont <= ADD;
				read_req <= 1'b1;
			end
			INC_PC1:begin
				state <= Decode;
				WenPC <= 1'b1;
				WenInstr <= 1'b1;
				ResCont <= alu;
				read_req <= 1'b0;
			end
			Decode:begin
				ALUSrcACont <= rs1;
				WenInstr <= 1'b0;
				WenPC <= 1'b0;
				case(Opcode)
					OP_LUI: state <= LUI0;
					OP_AUIPC: state <= AUIPC0;
					OP_JAL: state <= JAL0;
					OP_JALR: state <= JALR0;
					OP_B: state <= B0;
					OP_I: state <= I0;
					OP_S: state <= S0;
					OP_RI: state <= RI0;
					OP_R: state <= RI0;
					OP_SYSTEM: state <= SYSTEM0;
					OP_A: state <= A0;
					default: state <= Error;
				endcase
			end
			WrReg:begin
				if(ALUCont == DIV | ALUCont == REM) begin
					div_cnt <= div_cnt + 1'b1;
					if(div_cnt == 4'hf) begin
						state <= Fetch;
						div_cnt <= 4'h0;
					end
					else
						state <= WrReg;
				end
				else
					state <= Fetch;
				ResCont <= alu;
				WenRegfile <= 1'b1;
			end
			RI0:begin
				state <= RI1;
				if(Opcode == OP_R)
					ALUSrcBCont <= rs2;
				else
					ALUSrcBCont <= extimmB;
			end
			RI1:begin
				state <= WrReg;
				if(Opcode == OP_R && (Funct7 != 7'b0 && Funct7 != 7'b0100000)) 
					//RV32M
					case(Funct3)
						3'b000:	//MUL
							{MULH, ALUCont} <= {1'b0, MUL};
						3'b001://MULH
							{MULH, ALUCont} <= {1'b1, MUL};
						3'b010://MULHSU
							{MULH, ALUCont} <= {1'b1, MUL};
						3'b011://MULHU
							{MULH, ALUCont} <= {1'b1, MUL};
						3'b100://DIV
							ALUCont <= DIV;
						3'b101://DIVU
							ALUCont <= DIV;
						3'b110://REM
							ALUCont <= REM;
						3'b111://REMU
							ALUCont <= REM;
						default
							ALUCont <= FAULT;
					endcase
				else
					case(Funct3)
						3'b000:
							if(decode_type == Rtype)
								if(Funct7 == 7'b0)
									ALUCont <= ADD;
								else
									ALUCont <= SUB;
							else
								ALUCont <= ADD;
						3'b001:
							ALUCont <= SLL;
						3'b010:
							ALUCont <= SLT;
						3'b011:
							ALUCont <= SLTU;
						3'b100:
							ALUCont <= XOR;
						3'b101:
							if(Funct7 == 7'b0)
								ALUCont <= SRL;
							else
								ALUCont <= SRA;
						3'b110:
							ALUCont <= OR;
						3'b111:
							ALUCont <= AND;
						default:
							ALUCont <= FAULT;
					endcase
			end
			S0:begin
				state <= S1;
				ALUSrcBCont <= extimmB;
			end
			S1:begin
				state <= S2;
				ALUCont <= ADD;
				MemStrb <= Funct3;
			end
			S2:begin
				state <= (DataValid) ? Fetch : S2;
				ResCont <= alu;
				AddrSrcCont <= res_addr;
				WenMem <= 1'b1;
			end
			I0:begin
				state <= I1;
				ALUSrcBCont <= extimmB;
			end
			I1:begin
				state <= I2;
				ALUCont <= ADD;
				MemStrb <= Funct3;
			end
			I2:begin
				state <= (DataValid) ? I3 : I2;
				AddrSrcCont <= res_addr;
				read_req <= 1'b1;
				ResCont <= alu;
			end
			I3:begin
				state <= Fetch;
				read_req <= 1'b0;
				ResCont <= rddata;
				AddrSrcCont <= pc_addr;
				WenRegfile <= 1'b1;
			end
			LUI0:begin
				state <= LUI1;
				ALUSrcACont <= zeroA;
				ALUSrcBCont <= extimmB;
			end
			LUI1:begin
				state <= WrReg;
				ALUCont <= ADD;
			end
			AUIPC0:begin
				state <= AUIPC1;
				ALUSrcACont <= pc_inc;
				ALUSrcBCont <= imm_m4;
			end
			AUIPC1:begin
				state <= AUIPC2;
				ALUCont <= ADD;
			end
			AUIPC2:begin
				state <= AUIPC3;
				ResCont <= alu;
				ALUSrcACont <= src_res;
				ALUSrcBCont <= extimmB;
			end
			AUIPC3:begin
				state <= WrReg;
			end
			JAL0:begin
				state <= JAL1;
				ALUSrcACont <= pc_inc;
				ALUSrcBCont <= imm_m4;
			end
			JAL1:begin
				state <= WrPC0;
				ResCont <= nowpc;
				WenRegfile <= 1'b1;
				ALUCont <= ADD;
			end
			WrPC0:begin
				state <= WrPC1;
				WenRegfile <= 1'b0;
				ALUSrcACont <= src_res;
				ALUSrcBCont <= extimmB;
				ResCont <= alu;
			end
			WrPC1:begin
				state <= WrPC2;
			end
			WrPC2:begin
				ResCont <= alu;
				state <= Fetch;
				WenPC <= 1'b1;
			end
			JALR0:begin
				state <= JALR1;
				ResCont <= nowpc;
				WenRegfile <= 1'b1;
				ALUSrcACont <= rs1;
				ALUSrcBCont <= extimmB;
			end
			JALR1:begin
				state <= WrPC2;
				WenRegfile <= 1'b0;
				ALUCont <= ADD;
			end
			B0:begin
				state <= B1;
				ALUSrcACont <= rs1;
				ALUSrcBCont <= rs2;
			end
			B1:begin
				state <= B2;
				case(Funct3)
					3'b000:ALUCont <= TEST;
					3'b001:ALUCont <= TEST;
					3'b100:ALUCont <= SLT;
					3'b101:ALUCont <= SLT;
					3'b110:ALUCont <= SLTU;
					3'b111:ALUCont <= SLTU;
					default:ALUCont <= FAULT;
				endcase
			end
			B2:begin
				//ALUSrcACont <= rs1;
				//ALUSrcBCont <= rs2;
				case(Funct3)
					3'b000:
						if(ALUFlag) state <= B3;
						else state <= Fetch;
					3'b001:
						if(~ALUFlag) state <= B3;
						else state <= Fetch;
					3'b100:
						if(ALUFlag) state <= B3;
						else state <= Fetch;
					3'b101:
						if(~ALUFlag) state <= B3;
						else state <= Fetch;
					3'b110:
						if(ALUFlag) state <= B3;
						else state <= Fetch;
					3'b111:
						if(~ALUFlag) state <= B3;
						else state <= Fetch;
					default: state <= Error;
				endcase
			end
			B3:begin
				state <= B4;
				ALUSrcACont <= pc_inc;
				ALUSrcBCont <= imm_m4;
			end
			B4:begin
				state <= WrPC0;
				ALUCont <= ADD;
			end
			A0:begin
				case(Funct7 >> 2)
					5'b00001:begin
						state <= A1;
						ALUSrcBCont <= zeroB;
						MemStrb <= Funct3;
					end
					default: state <= Error;
				endcase
			end
			A1:begin
				state <= A2;
				ALUCont <= ADD;
			end
			A2:begin
				state <= (DataValid) ? A3 : A2;
				AddrSrcCont <= res_addr;
				read_req <= 1'b1;
				ResCont <= alu;
				WenRS2 <= 1'b0;
			end
			A3:begin
				state <= A4;
				read_req <= 1'b0;
				ResCont <= rddata;
				WenRegfile <= 1'b1;
			end
			A4:begin
				state <= (DataValid) ? Fetch : A4;
				AddrSrcCont <= res_addr;
				ResCont <= alu;
				WenRegfile <= 1'b0;
				WenMem <= 1'b1;
			end
			SYSTEM0:begin
				if(Funct3 == 3'b000 && Funct7 == 7'h0) begin
					state <= ECALL0;
					ALUSrcACont <= pc_inc;
					ALUSrcBCont <= zeroB;
					ECALL <= 1'b1;
				end
				else if(Funct3 == 3'b000 && Funct7 == 7'h18) begin
					state <= MRET0;
					ALUSrcACont <= zeroA;
					ALUSrcBCont <= csr;
					MRET <= 1'b1;
				end
				else if(RunLevel != 2'h0) begin
					state <= SYSTEM1;
					ALUSrcBCont <= csr;
					ALUSrcACont <= zeroA;
				end
				else
					state <= Error;
			end
			SYSTEM1:begin
				state <= SYSTEM2;
				ALUCont <= ADD;
			end
			SYSTEM2:begin
				state <= SYSTEM3;
				WenRegfile <= 1'b1;
				case(Funct3)
					3'b001:{ALUCont, ALUSrcACont, ALUSrcBCont} <= {ADD, rs1, zeroB};
					3'b010:{ALUCont, ALUSrcACont, ALUSrcBCont} <= {OR, rs1, csr};
					3'b011:{ALUCont, ALUSrcACont, ALUSrcBCont} <= {CLR, rs1, csr};
					3'b101:{ALUCont, ALUSrcACont, ALUSrcBCont} <= {ADD, extimmA, zeroB};
					3'b110:{ALUCont, ALUSrcACont, ALUSrcBCont} <= {OR, extimmA, csr};
					3'b111:{ALUCont, ALUSrcACont, ALUSrcBCont} <= {CLR, extimmA, csr};
				endcase
			end
			SYSTEM3:begin
				state <= SYSTEM4;
				WenRegfile <= 1'b0;
			end
			SYSTEM4:begin
				state <= Fetch;
				WenCSR <= 1'b1;
			end
			ECALL0:begin
				state <= ECALL1;
				ALUCont <= ADD;
				ALUSrcACont <= zeroA;
				ALUSrcBCont <= csr;
			end
			ECALL1:begin
				state <= ECALL2;
				ResCont <= alu;
				WenCSR <= 1'b1;
			end
			ECALL2:begin
				state <= (DataValid) ? ECALL3 : ECALL2;
				WenCSR <= 1'b0;
				AddrSrcCont <= res_addr;
				read_req <= 1'b1;
			end
			ECALL3:begin
				state <= Fetch;
				read_req <= 1'b0;
				ResCont <= rddata;
				WenPC <= 1'b1;
				ECALL <= 1'b0;
				INTR <= 1'b0;
			end
			MRET0:begin
				state <= MRET1;
				MRET <= 1'b0;
				ALUCont <= ADD;
			end
			MRET1:begin
				state <= Fetch;
				ResCont <= alu;
				WenPC <= 1'b1;
			end
			INTR0:begin
				state <= ECALL0;
				ALUSrcACont <= pc_inc;
				ALUSrcBCont <= zeroB;
				INTR <= 1'b1;
			end
			Error: state <= Error;
			default:begin
				state <= Error;
			end
		endcase
	end
end
endmodule

module CONT_STATE_DEBUG(
	input [5:0] state,
	output [5:0] state_debug
);
assign state_debug = state;

endmodule

