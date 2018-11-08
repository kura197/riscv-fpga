module SDRAM_RISCV(
	input clk,reset,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout   [15:0]	DRAM_DQ,
	output DRAM_LDQM,
	output DRAM_RAS_N,
	output DRAM_UDQM,
	output DRAM_WE_N,
	input rd_req_buf,
	input wr_req_buf,
	input [31:0] mem_addr,
	input [31:0] indata,
	output reg [31:0] outdata,
	output init,
	output reg rd_valid,
	output reg wr_valid,
	input [2:0] mem_size
);

`include "sdram.h"

wire cur_act;
reg rd_req;
reg wr_req;
wire rd_data_valid;
wire [15:0] rd_data;
reg [15:0] wr_data;
wire [31:0] addr;
wire cur_idle;
SDRAM_CONTROLLER sdram(
	.clk(clk),
	.reset(reset),
	.DRAM_ADDR(DRAM_ADDR),
	.DRAM_BA(DRAM_BA),
	.DRAM_CAS_N(DRAM_CAS_N),
	.DRAM_CKE(DRAM_CKE),
	.DRAM_CLK(DRAM_CLK),
	.DRAM_CS_N(DRAM_CS_N),
	.DRAM_DQ(DRAM_DQ),
	.DRAM_LDQM(DRAM_LDQM),
	.DRAM_RAS_N(DRAM_RAS_N),
	.DRAM_UDQM(DRAM_UDQM),
	.DRAM_WE_N(DRAM_WE_N),
	.addr(addr),
	.rd_data(rd_data),
	.wr_data(wr_data),
	.rd_req(rd_req),
	.wr_req(wr_req),
	.rd_data_valid(rd_data_valid),
	.init(init),
	.cur_act(cur_act),
	.cur_idle(cur_idle),
	.mem_size(mem_size),
	.high_byte(high_byte)
);

wire write_en = cur_idle ? wr_req_buf : write_en;
wire high_byte = mem_addr[0];
reg high;
always @(posedge clk, posedge reset)
	if(reset) begin
		{rd_valid,high,rd_req} <= 3'b000;
		outdata <= 32'h0;
	end
	else if(~write_en & rd_req_buf) begin
		if(cur_idle)	rd_req <= 1'b1;
		else	rd_req <= 1'b0;
		rd_valid <= 1'b0;
		if(rd_data_valid)
			if(~high) begin
				if(mem_size == 3'b000)
					if(high_byte)
						outdata <= {{24{rd_data[15]}}, rd_data[15:8]};
					else
						outdata <= {{24{rd_data[7]}}, rd_data[7:0]};
				else if(mem_size == 3'b100)
					if(high_byte)
						outdata <= {24'h0, rd_data[15:8]};
					else
						outdata <= {24'h0, rd_data[7:0]};
				else
				outdata[15:0] <= rd_data;
				high <= 1'b1;
			end
			else begin
				case(mem_size)
					3'b001:
						outdata[31:16] <= {16{outdata[15]}};
					3'b010:
						outdata[31:16] <= rd_data;
					3'b101:
						outdata[31:16] <= 16'h0;
					default:
						outdata <= outdata;
				endcase
				high <= 1'b0;
				//rd_req <= 1'b0;
				rd_valid <= 1'b1;
			end
	end
	else begin
		rd_valid <= 1'b0;
		rd_req <= 1'b0;
	end

reg wrhighw;
//wire clk_rev = ~clk;
always @(posedge clk, posedge reset)
	if(reset)
		{wr_valid, wr_req} <= 2'b00;
	else if(write_en) begin
		if(cur_idle)	wr_req <= 1'b1;
		else wr_req <= 1'b0;
		wr_valid <= 1'b0;
		if(cur_act & ~wrhighw)  begin
			if(mem_size == 3'b000)
				if(high_byte)
					wr_data[15:8] <= indata[7:0];
				else
					wr_data[7:0] <= indata[7:0];
			else
				wr_data <= indata[15:0];
			wrhighw <= 1'b1;
		end
		else if(wrhighw) begin
			wr_data <= indata[31:16];
			wrhighw <= 1'b0;
			wr_valid <= 1'b1;
		end
	end
	else begin
		wrhighw <= 1'b0;
		wr_valid <= 1'b0;
		wr_req <= 1'b0;
	end

//assign rd_req = (wr_req_buf & ~rdhighw) ? 1'b0 : rd_req_buf;
//assign addr = (cur_act) ? {1'b0,mem_addr[31:1] + 1'b1} : {1'b0,mem_addr[31:1]};
assign addr = {1'b0, mem_addr[31:1]};
//assign wr_req = wr_req_buf;
//assign wr_data = (cur_act) ? indata[31:16] : indata[15:0];
//assign wr_valid = cur_act & wr_req & ~rd_req;


endmodule
