module SD_SPI_TOP(
	//200kHz
	input CLK_init,
	input CLK_RAM,
	//20MHz
	input CLK_normal,
	input RST,
	output SCK,
	output MOSI,
	input MISO,
	output CS,
	//output [7:0] received_data_debug,
	output init_end,
	//output [7:0] send_data_debug,
	//output [3:0] init_state
	input [31:0] addr,
	input read_req,
	output recv_block_valid,
	input [8:0] spi_ram_rd_addr,
	output [7:0] spi_ram_output
);
//assign received_data_debug = received_data;
//assign init_end_debug = init_end;
//assign send_data_debug = init_send_data;

//assign recv_block_valid = recv_all_valid;
wire blockstart_end;
assign recv_block_valid = blockstart_end;
EDGE_TO_PULSE #(1,0) gen_block_valid(CLK_init, blockstart, blockstart_end);
//EDGE_TO_PULSE #(1,0) gen_block_valid(CLK, blockstart, blockstart_end);

`include "sd_spi.h"
wire CLK = (change_clock) ? CLK_normal : CLK_init;
//wire CLK = CLK_init;
wire [7:0] send_data_queue;
wire [7:0] received_data;
wire startflag_init;
reg startflag_normal;
wire startflag = (init_end) ? startflag_normal : startflag_init;
wire start_send;
wire recv_valid;
wire init_CS;
//wire init_end;
wire [7:0] init_send_data;
reg [7:0] normal_send_data;
wire recv_all_valid;
wire [9:0] recv_num_buf_init;
reg [9:0] recv_num_buf_normal;
wire [9:0] recv_num_buf = (init_end) ? recv_num_buf_normal : recv_num_buf_init;
wire blockread = init_end;
wire blockstart;
wire change_clock;
SPI_MASTER spi_master(
	.CLK(CLK),
	.RST(RST),
	.SCK(SCK),
	.MOSI(MOSI),
	.MISO(MISO),
	.CS(CS),
	.send_data_queue(send_data_queue),
	.received_data(received_data),
	.startflag(startflag),
	.start_send(start_send),
	.recv_valid(recv_valid),
	.init_CS(init_CS),
	.recv_all_valid(recv_all_valid),
	.recv_num_buf(recv_num_buf),
	.blockstart(blockstart),
	.blockread(blockread)
);

SD_INIT sd_init(
	.CLK(CLK),
	.RST(RST),
	.CS(CS),
	.recv_data(received_data),
	.startflag(startflag_init),
	.recv_valid(recv_valid),
	.start_send(start_send),
	.send_data(init_send_data),
	.init_CS(init_CS),
	.init_end(init_end),
	//.state_debug(init_state),
	.change_clock(change_clock),
	.recv_num(recv_num_buf_init)
);

assign send_data_queue = (~init_end) ? init_send_data : normal_send_data;

reg [8:0] spi_ram_wr_addr;
wire [8:0] spi_ram_addr = (blockstart) ? spi_ram_wr_addr : spi_ram_rd_addr;
wire spi_ram_wen_pulse;
//EDGE_TO_PULSE(CLK_RAM, spi_ram_wen, spi_ram_wen_pulse);
spi_ram	spi_ram_inst (
	.address ( spi_ram_addr ),
	.clock ( CLK ),
	//.clock ( CLK_RAM ),
	.data ( received_data ),
	.wren ( spi_ram_wen ),
	//.wren ( spi_ram_wen_pulse ),
	.q ( spi_ram_output )
	);
wire spi_ram_wen;
assign spi_ram_wen = blockstart & recv_valid & blockread;
always @(posedge CLK)
	if(read_state == 2'h0)
		spi_ram_wr_addr <= 9'h0;
	else if(spi_ram_wen)
		spi_ram_wr_addr <= spi_ram_wr_addr + 1'b1;


reg [1:0] read_state;
reg [2:0] cnt;
reg valid;
wire [1:0] debug_state;
state_debug debug(read_state,debug_state);

always @(posedge CLK, posedge RST)
	if(RST) begin
		read_state <= 2'h0;
		cnt <= 3'h0;
		valid <= 1'b0;
		normal_send_data <= CMD17;
	end
	else if(init_end)
		case(read_state)
			2'h0:
				if(read_req) begin
					read_state <= 2'h1;
					normal_send_data <= CMD17;
				end
				else read_state <= 2'h0;
			2'h1:begin
				startflag_normal <= 1'b1;
				recv_num_buf_normal <= 10'd511;
				if(start_send) begin
					cnt <= cnt + 1'b1;
					if(cnt == 3'h0)
						normal_send_data <= addr[31:24];
					else if(cnt == 3'h1)
						normal_send_data <= addr[23:16];
					else if(cnt == 3'h2)
						normal_send_data <= addr[15:8];
					else if(cnt == 3'h3)
						normal_send_data <= addr[7:0];
					else if(cnt == 3'h4) 
						normal_send_data <= 8'hFF;
					else
						read_state <= 2'h2;
				end
			end
			2'h2:
				if(recv_all_valid) begin
					startflag_normal <= 1'b0;
					valid <= 1'b1;
					read_state <= 2'h0;
					cnt <= 3'h0;
				end
				else
					read_state <= 2'h2;
		endcase

endmodule

module state_debug(
	input [1:0] state,
	output [1:0] debug_state
);
assign debug_state = state;
endmodule
