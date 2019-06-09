module SDRAM_CONTROLLER(
	input clk,reset,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output      	DRAM_CAS_N,
	output      	DRAM_CKE,
	output      	DRAM_CLK,
	output      	DRAM_CS_N,
	inout   [15:0]	DRAM_DQ,
	output      	DRAM_LDQM,
	output      	DRAM_RAS_N,
	output      	DRAM_UDQM,
	output      	DRAM_WE_N,
	input [31:0] addr,
	output [15:0] rd_data,
	input [15:0] wr_data,
	input rd_req,wr_req,
	output rd_data_valid,
	output init,
	output reg cur_act,
	output reg cur_idle,
	input [2:0] mem_size,
	input high_byte
);

`include "sdram.h"
wire init_CS_N,init_WE_N,init_RAS_N,init_CAS_N,init_CKE,init_UDQM,init_LDQM;
wire [12:0] init_ADDR;
wire [1:0] init_BA;

wire run_CS_N,run_WE_N,run_RAS_N,run_CAS_N,run_CKE,run_UDQM,run_LDQM;
reg [12:0] run_ADDR;
reg [1:0] run_BA;
assign run_CS_N = 1'b0;

assign DRAM_ADDR = ~init ? init_ADDR : run_ADDR;
assign DRAM_BA = ~init ? init_BA : run_BA;
assign DRAM_CAS_N = ~init ? init_CAS_N : run_CAS_N;
assign DRAM_CS_N = ~init ? init_CS_N : run_CS_N;
assign DRAM_WE_N = ~init ? init_WE_N : run_WE_N;
assign DRAM_RAS_N = ~init ? init_RAS_N : run_RAS_N;
assign DRAM_CKE = ~init ? init_CKE : run_CKE;
assign DRAM_UDQM = ~init ? init_UDQM : run_UDQM;
assign DRAM_LDQM = ~init ? init_LDQM : run_LDQM;

wire clk_rev;
assign clk_rev = ~clk;

assign run_CKE = 1'b1;
assign DRAM_CLK = clk_rev;

reg [2:0] DRAM_CMD;
assign {run_RAS_N, run_CAS_N, run_WE_N} = DRAM_CMD;
reg [1:0] DRAM_DQM;
assign run_LDQM = DRAM_DQM[0];
assign run_UDQM = DRAM_DQM[1];

SDRAM_INIT sdram_init(clk,reset,init,init_LDQM,init_UDQM,init_CKE,init_RAS_N,init_CS_N,init_CAS_N,init_WE_N,init_ADDR,init_BA);

//492clock
localparam REF_LIMIT = 400;
reg [15:0] refresh_cnt;
reg refresh_en;
reg refresh;
always @(posedge clk, posedge reset)
	if(reset)
		{refresh_en,refresh_cnt} <= 17'h0;
	else if(refresh_cnt > REF_LIMIT) begin
		if(refresh)
			{refresh_en,refresh_cnt} <= 17'h0;
		else 
			refresh_en <= 1'b1;
	end
	else 
		refresh_cnt <= refresh_cnt + 1'b1; 

reg read;
reg wait_valid0;
reg wait_valid1;
reg wait_valid2;
reg wait_valid3;
assign rd_data_valid = wait_valid3 | wait_valid2;
always @(posedge clk) begin
	wait_valid0 <= (read & cur_act);
	wait_valid1 <= wait_valid0;
	wait_valid2 <= wait_valid1;
	wait_valid3 <= wait_valid2;
end
//assign rd_data = rd_data_valid ? DRAM_DQ : 16'hzzzz;
assign rd_data = rd_data_valid ? DRAM_DQ : 16'h0;

//wire SameRowAndBank;
//assign SameRowAndBank = ((cur_ROW == addr[22:10]) & (cur_BA == addr[24:23])) ? 1'b1 : 1'b0;
reg output_en;
assign DRAM_DQ = output_en ? wr_data : 16'hz;
reg [2:0] state;
reg [7:0] cnt;
reg [2:0] nop_cause;
wire [2:0] state_debug;
STATE_DEBUG debug(state,state_debug);
always @(posedge clk, posedge reset)
	if(reset) begin
		state <= IDLE;
		cnt <= 8'h0;
		cur_act <= 1'b0;
		refresh <= 1'b0;
		cur_idle <= 1'b1;
	end
	else if(init)
		case(state)
			IDLE:begin
				cur_act <= 1'b0;
				if(rd_req | wr_req) begin
					DRAM_CMD <= DRAM_CMD_ACTIVE;
					run_BA <= addr[24:23];
					run_ADDR <= addr[22:10];
					read <= rd_req;
					DRAM_DQM <= 2'b11;
					state <= NOP;
					cnt <= 8'h0;
					nop_cause <= IDLE;
					cur_idle <= 1'b0;
				end
				else begin
					DRAM_CMD <= DRAM_CMD_NOP;
					run_BA <= 2'h0;
					run_ADDR <= 13'h0;
					DRAM_DQM <= 2'b11;
					if(refresh_en) begin
						state <= NOP;
						cnt <= 8'h0;
						DRAM_CMD <= DRAM_CMD_REFRESH;
						nop_cause <= REFRESH;
						refresh <= 1'b1;
					end
					else
						state <= IDLE;
				end
			end
			ACT:begin
				//cur_act <= 1'b1;
				DRAM_CMD <= read ? DRAM_CMD_READ : DRAM_CMD_WRITE;
				run_BA <= addr[24:23];
				run_ADDR[9:0] <= addr[9:0];
				//no auto precharge
				run_ADDR[12:10] <= 3'b0;
				if(read)
					DRAM_DQM <= 2'b00;
				else 
					case(mem_size)
						3'b000: if(high_byte) DRAM_DQM <= 2'b01;
								else DRAM_DQM <= 2'b10;
						3'b001: DRAM_DQM <= 2'b00;
						3'b010: DRAM_DQM <= 2'b00;
						default: DRAM_DQM <= 2'b00;
					endcase
				//read <= rd_req;
				output_en <= read ? 1'b0 : 1'b1;
				//state <= ((rd_req | wr_req) & SameRowAndBank) ? ACT : PRECH;
				//if((rd_req | wr_req) & SameRowAndBank) begin
				//	state <= ACT;
				//	cur_act <= 1'b1;
				//end
				//else begin
					state <= NOP;
					nop_cause <= read ? READ : WRITE;
					cur_act <= 1'b0;
					cnt <= 8'h0;
				//end
			end
			PRECH:begin
				//cur_act <= 1'b0;
				DRAM_CMD <= DRAM_CMD_PRECHARGE;  
				run_BA <= 2'b00;
				run_ADDR <= 11'b100_0000_0000; 
				DRAM_DQM <= 2'b11;
				state <= NOP;
				cnt <= 8'h0;
				nop_cause <= PRECH;
			end
			NOP:begin
				DRAM_CMD <= DRAM_CMD_NOP;
				case(nop_cause)
					IDLE:begin
						cnt <= cnt + 1'b1;
						if(cnt == Trcd) begin
							state <= ACT;
							cur_act <= 1'b1;
						end
					end
					PRECH:begin
						cnt <= cnt + 1'b1;
						if(cnt == Trp) begin
							state <= IDLE;
							cur_idle <= 1'b1;
						end
					end
					REFRESH:begin
						cnt <= cnt + 1'b1;
						if(cnt == Trc) begin
							state <= IDLE;
							refresh <= 1'b0;
							cur_idle <= 1'b1;
						end
					end
					WRITE:begin
						cnt <= cnt + 1'b1;
						if(cnt == 1'b0)
							if(mem_size == 3'b000 || mem_size == 3'b001)
								DRAM_DQM <= 2'b11;
							else
								DRAM_DQM <= 2'b00;
						else if(cnt == 1'b1) begin
							output_en <= 1'b0;
							DRAM_DQM <= 2'b11;
						end
						else if(cnt == Tdpl)
							state <= PRECH;
					end
					READ:begin
						cnt <= cnt + 1'b1;
						if(cnt == 1'b1)
							state <= PRECH;
					end
				endcase
			end
		endcase


endmodule

module STATE_DEBUG(
	input [2:0] state,
	output [2:0] state_debug
);
assign state_debug = state;
endmodule
