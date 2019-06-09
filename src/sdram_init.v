module SDRAM_INIT(
	input clk,reset,
	output reg complete,
	output DRAM_LDQM,
	output DRAM_UDQM,
	output DRAM_CKE,
	output DRAM_RAS_N,
	output DRAM_CS_N,
	output DRAM_CAS_N,
	output DRAM_WE_N,
	output reg [12:0] DRAM_ADDR,
	output reg [1:0] DRAM_BA
);

`include "sdram.h"

assign DRAM_CS_N = 1'b0;
reg [1:0] DRAM_DQM;
reg [2:0] DRAM_CMD;
assign {DRAM_UDQM,DRAM_LDQM} = DRAM_DQM;
assign {DRAM_RAS_N, DRAM_CAS_N, DRAM_WE_N} = DRAM_CMD;
assign DRAM_CKE = 1'b1;

//wire clk_rev;
//assign clk_rev = ~clk;


reg [15:0] cnt;
reg [1:0] stage;
localparam nop = 2'h0;
localparam precharge = 2'h1;
localparam auto_refresh = 2'h2;
localparam loadmode = 2'h3;
//always @(posedge clk_rev, posedge reset)
always @(posedge clk, posedge reset)
	if(reset) begin
		complete <= 1'b0;
		stage <= nop;
		cnt <= 16'b0;
	end
	else 
		case(stage)
			nop: begin
				cnt <= cnt + 1'b1;
				DRAM_CMD <= DRAM_CMD_NOP;
				DRAM_DQM <= 2'b11;
				if(cnt == 20000) begin
					stage <= stage + 1'b1;
					cnt <= 16'h0;
				end
			end
			precharge: begin
				DRAM_CMD <= DRAM_CMD_PRECHARGE;  
				DRAM_BA <= 2'b00;
				DRAM_ADDR <= 11'b100_0000_0000; 
				cnt <= cnt + 1'b1;
				if(cnt == Trp) begin
					stage <= stage + 1'b1;
					cnt <= 16'h0;
				end
			end
			auto_refresh:begin
				cnt <= cnt + 1'b1;
				if(cnt[7:0] == 8'h0)	DRAM_CMD <= DRAM_CMD_REFRESH;  
				else	DRAM_CMD <= DRAM_CMD_NOP;
				if(cnt[7:0] == Trc) begin
					cnt <= {cnt[15:8] + 1'b1, 8'h0};
					if(cnt[15:8] == 8'h8)
						stage <= stage + 1'b1;
				end
			end
			loadmode:begin
				DRAM_BA <= 2'b00;
				DRAM_ADDR <= 13'b000_0_00_010_0_001;
				DRAM_CMD <= DRAM_CMD_LOADMODE;
				complete <= 1'b1;
			end
		endcase




endmodule
