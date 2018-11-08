module SD_INIT(
	//freq = 200kHz
	input CLK,
	input RST,
	input CS,
	input [7:0] recv_data,
	output reg startflag,
	input recv_valid,
	input start_send,
	output reg [7:0] send_data,
	output reg [9:0] recv_num,
	output init_CS,
	output reg init_end,
	output reg change_clock,
	output [3:0] state_debug
);
assign state_debug = state;

`include "sd_spi.h"
localparam Wait_1ms = 0;
localparam Dummy = 1;
localparam Send_CMD0 = 2;
localparam Recv_CMD0 = 3;
localparam Send_CMD8 = 4;
localparam Recv_CMD8 = 5;
localparam Send_CMD55 = 6;
localparam Recv_CMD55 = 7;
localparam Send_ACMD41 = 8;
localparam Recv_ACMD41 = 9;
localparam Send_CMD58 = 10;
localparam Recv_CMD58 = 11;
localparam INIT = 12;

reg [3:0] state;
reg [9:0] cnt;
reg [11:0] R7_resp;
reg [5:0] ext_cnt;
assign init_CS = (state == Dummy) | (change_clock & ~init_end);
always @(posedge CLK, posedge RST)
	if(RST) begin
		state <= 0;
		cnt <= 10'h1;
		init_end <= 1'b0;
		startflag <= 1'b0;
		change_clock <= 1'b0;
		ext_cnt <= 6'h1;
	end
	else if(~init_end)
		case(state)
			Wait_1ms:
				if(cnt == 10'h0)	state <= Dummy;
				else	cnt <= cnt + 1'b1;
			Dummy:begin
				recv_num <= 10'h0;
				startflag <= 1'b1;
				send_data <= 8'hff;
				//if(recv_valid)
					if(cnt == 10'd100) begin
						state <= Send_CMD0;
						startflag <= 1'b0;
						cnt <= 10'h0;
						send_data <= CMD0;
					end
					else	cnt <= cnt + 1'b1;
			end
			Send_CMD0:begin
				if(cnt <= 10'd10)
					cnt <= cnt + 1'b1;
				else begin
					startflag <= 1'b1;
					if(start_send) begin 
						cnt <= cnt + 1'b1;
						if(cnt < 10'd15)	send_data <= 8'h0;
						else if(cnt == 10'd15)	begin
							send_data <= 8'h95;
							state <= Recv_CMD0;
						end
					end
				end
			end
			Recv_CMD0:
					if(recv_valid && recv_data == 8'h01) begin
						state <= Send_CMD8;
						startflag <= 1'b0;
						cnt <= 10'h0;
						send_data <= CMD8;
					end
					else if(start_send)
						send_data <= 8'hff;
			Send_CMD8:begin
				if(cnt > 10'hf) begin
					startflag <= 1'b1;
					recv_num <= 10'h4;
					if(start_send) begin
						cnt <= cnt + 1'b1;
						if(cnt == 10'h10 || cnt == 10'h11)
							send_data <= 8'h00;
						else if(cnt == 10'h12)
							send_data <= 8'h01;
						else if(cnt == 10'h13)
							send_data <= 8'haa;
						else if(cnt == 10'h14) begin
							send_data <= 8'h87;
							state <= Recv_CMD8;
							cnt <= 10'h0;
						end
					end
				end
				else if(CS)
					cnt <= cnt + 1'b1;
			end
			Recv_CMD8:
				if(recv_valid) begin
					cnt <= cnt + 1'b1;
					if(cnt == 10'h3) 	R7_resp[11:8] <= recv_data[3:0];
					else if(cnt == 10'h4)	R7_resp[7:0] <= recv_data;
				end
				else if(cnt == 10'h5) begin
					if(R7_resp == 12'h1aa) begin
						startflag <= 1'b0;
						cnt <= 10'h0;
						send_data <= CMD55;
						//send_data <= CMD1;
						state <= Send_CMD55;
					end
					else begin
						startflag <= 1'b0;
						cnt <= 10'h0;
						send_data <= CMD8;
						state <= Send_CMD8;
					end
				end
				else if(start_send)
					send_data <= 8'hff;
			Send_CMD55:
				if(cnt > 10'hf) begin
					startflag <= 1'b1;
					recv_num <= 10'h0;
					if(start_send) begin
						cnt <= cnt + 1'b1;
						if(cnt <= 10'h14) begin
							send_data <= 8'h00;
							state <= Recv_CMD55;
							cnt <= 10'h0;
						end
					end
				end
				else if(CS)
					cnt <= cnt + 1'b1;
			Recv_CMD55:
					if(recv_valid) 
						if(recv_data == 8'h01) begin
							state <= Send_ACMD41;
							startflag <= 1'b0;
							cnt <= 10'h0;
							send_data <= ACMD41;
						end
						else begin
							startflag <= 1'b0;
							cnt <= 10'h0;
							send_data <= CMD55;
							//send_data <= CMD1;
							state <= Send_CMD55;
						end
					else if(start_send)
						send_data <= 8'hff;
			Send_ACMD41:
				if(cnt > 10'hf) begin
					startflag <= 1'b1;
					recv_num <= 10'h0;
					if(start_send) begin
						cnt <= cnt + 1'b1;
						if(cnt <= 10'h10)
							send_data <= 8'h40;
						else if(cnt <= 10'h13)
							send_data <= 8'h00;
						else if(cnt == 10'h14) begin
							send_data <= 8'h01;
							state <= Recv_ACMD41;
							cnt <= 10'h0;
						end
					end
				end
				else if(CS)
					cnt <= cnt + 1'b1;
			Recv_ACMD41:
					if(recv_valid) 
						if(recv_data == 8'h00) begin
							state <= Send_CMD58;
							startflag <= 1'b0;
							cnt <= 10'h0;
							send_data <= CMD58;
						end
						else begin
							startflag <= 1'b0;
							cnt <= 10'h0;
							send_data <= CMD55;
							//send_data <= CMD1;
							state <= Send_CMD55;
						end
					else if(start_send)
						send_data <= 8'hff;
			Send_CMD58:begin
				if(cnt > 10'hf) begin
					startflag <= 1'b1;
					recv_num <= 10'h4;
					if(start_send) begin
						cnt <= cnt + 1'b1;
						if(cnt <= 10'h13)
							send_data <= 8'h00;
						else if(cnt == 10'h14) begin
							send_data <= 8'hff;
							state <= Recv_CMD58;
							cnt <= 10'h0;
						end
					end
				end
				else if(CS)
					cnt <= cnt + 1'b1;
			end
			Recv_CMD58:
				if(recv_valid)
					cnt <= cnt + 1'b1;
				else if(cnt == 10'h5) begin
					startflag <= 1'b0;
					cnt <= 10'h0;
					send_data <= 8'hff;
					state <= INIT;
				end
				else if(start_send)
					send_data <= 8'hff;
			INIT:begin
				change_clock <= 1'b1;
				cnt <= cnt + 1'b1;
				if(cnt == 10'd1023) begin
				//if(cnt == 10'h10)
					if(ext_cnt == 6'h0)
						init_end <= 1'b1;
					else
						ext_cnt <= ext_cnt + 1'b1;
				end
			end
			default:
				init_end <= 1'b1;
		endcase

endmodule
