module SPI_MASTER(
	input RST,
	input CLK,
	output  SCK,
	output MOSI,
	input MISO,
	output reg CS,
	input [7:0]	send_data_queue,
	output reg [7:0] received_data,
	input startflag,
	output reg start_send,
	output reg recv_valid,
	output reg recv_all_valid,
	input init_CS,
	input [9:0] recv_num_buf,
	output reg blockstart,
	input blockread
);

reg [7:0] send_data;
assign MOSI = (sending) ? send_data[7] : 1'b1;
//assign SCK = (sending) ? CLK : 1'b0;
assign SCK = CLK;
reg sending;
reg [3:0] cnt;
reg receiving;
reg presend;
reg [9:0] recv_num;
//reg blockstart;

always @(posedge CLK, posedge RST)
	if(RST) begin
		cnt <= 4'h0;
		CS <= 1'b1;
	end
	else if(presend) begin
		cnt <= cnt + 1'b1;
		if(cnt == 4'hf) begin
			if(startflag)	cnt <= 4'h8;
			else begin
				{presend, cnt} <= 5'h0;
				CS <= 1'b1;
			end
		end
	end
	else if(startflag) begin
		presend <= 1'b1;
		if(~init_CS)	CS <= 1'b0;
		else CS <= 1'b1;
	end
	else
		cnt <= 4'h0;

reg [2:0] recv_cnt;
reg [1:0] wait_crc;
reg recv_block_end;
always @(negedge CLK, posedge RST)
	if(RST) begin
		received_data <= 8'b0;
		recv_cnt <= 3'h0;
		receiving <= 1'b1;
		recv_num <= 10'h0;
		recv_valid <= 1'b0;
		recv_all_valid <= 1'b0;
		wait_crc <= 2'h0;
		recv_block_end <= 1'b0;
	end
	else if(sending)
		if(receiving) begin
			received_data <= {received_data[6:0], MISO};
			recv_cnt <= recv_cnt + 1'b1;
			recv_valid <= 1'b0;
			if(recv_cnt == 3'h7) begin
				recv_valid <= 1'b1;
				if(recv_num != 10'h0) begin
					recv_cnt <= 3'h0;
					if(~blockread | blockstart) 
						recv_num <= recv_num - 1'b1;
				end
				else if(wait_crc == 2'h3 | ~blockread) begin
					wait_crc <= 2'h0;
					receiving <= 1'b0;
					recv_all_valid <= 1'b1;
				end
				else begin
					wait_crc <= wait_crc + 1'b1;
					recv_block_end <= 1'b1;
					recv_cnt <= 3'h0;
				end
			end
		end
		//else if((MISO == 1'b0 && ~init_end) | (received_data == 8'hFE && init_end)) begin
		else if(MISO == 1'b0) begin
			received_data <= {received_data[6:0], MISO};
			recv_cnt <= 3'h1;
			recv_valid <= 1'b0;
			recv_all_valid <= 1'b0;
			receiving <= 1'b1;
			recv_num <= recv_num_buf;
		end
	else begin
		{recv_valid, recv_all_valid} <= 2'b00;
		recv_block_end <= 1'b0;
	end

reg blockstart_buf;
always @(posedge CLK)
	blockstart <= blockstart_buf;

always @(posedge CLK, posedge RST)
	if(RST)
		blockstart_buf <= 1'b0;
	//else if(recv_all_valid)
	else if(recv_block_end)
		blockstart_buf <= 1'b0;
	else if(blockread && recv_valid && received_data == 8'hFE)
		blockstart_buf <= 1'b1;

always @(posedge CLK, posedge RST)
	if(RST) begin
		send_data <= 8'b0;
		//CS <= 1'b1;
		sending <= 1'b0;
	end
	else if(cnt != 4'h0)
		if(cnt < 4'h7) begin
			//if(~init_CS)	CS <= 1'b0;
			//else CS <= 1'b1;
			send_data <= send_data_queue;
		end
		else if(cnt == 4'h7)
			sending <= 1'b1;
		else if(cnt == 4'hf) begin
			if(startflag)
				send_data <= send_data_queue;
			else begin
				//CS <= 1'b1;
				sending <= 1'b0;
			end
		end
		else begin
			send_data <= {send_data[6:0], 1'b0};
			//sending <= 1'b1;
			if(cnt == 4'h8) start_send <= 1'b1;
			else start_send <= 1'b0;
		end
	else
		send_data <= send_data_queue;


endmodule
