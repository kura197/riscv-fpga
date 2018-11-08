module PORT(
	input clk,reset,
	input [11:0] port_addr,
	input ReadReq,
	input WriteReq,
	output [31:0] read_data,
	input [31:0] write_data,
	output reg DataValid,
	output [31:0] sd_sect,
	output sd_load_req,
	input sd_load_valid,
	output reg [8:0] sd_buf_addr,
	input [7:0] sd_data,
	output reg [7:0] uart_tx_data,
	output reg uart_tx_start,
	input [7:0] uart_rx_data,
	input  uart_rx_recv,
    input kbd_valid,
    input [7:0] kbd_data,
	output [63:0] mtimecmp
);
localparam COM1 = 12'h3F8;
localparam TIMECMP_L = 12'h508;
localparam TIMECMP_H = 12'h50C;
localparam KBSTATP = 12'h64;    // kbd controller status port(I)
localparam KBDATAP = 12'h60;    // kbd data port(I)

wire [7:0] port_0x1F0 = sd_data;
reg [7:0] port_0x1F2; 
reg [7:0] port_0x1F3; 
reg [7:0] port_0x1F4; 
reg [7:0] port_0x1F5; 
reg [7:0] port_0x1F6; 
reg [7:0] port_0x1F7; 
reg [7:0] port_0x3FD;
reg [31:0] timecmp_L;
reg [31:0] timecmp_H;
assign mtimecmp = {timecmp_H, timecmp_L};
assign sd_sect = {port_0x1F6,port_0x1F5,port_0x1F4,port_0x1F3};
reg [7:0] read_port;
assign read_data = {24'h0, read_port};
reg sd_load_req_edge;
reg [7:0] kbd_stat;
EDGE_TO_PULSE gen_sd_req(clk, sd_load_req_edge, sd_load_req);

always @(posedge clk, posedge reset)
	if(reset) begin
		port_0x1F7 <= 8'h40;
		sd_buf_addr <= 9'h0;
		sd_load_req_edge <= 1'b0;
		DataValid <= 1'b0;
		port_0x3FD <= 8'h0;
		uart_tx_start <= 1'b0;
	end
	else begin
		if(port_0x1F7 == 8'h20) begin
			sd_load_req_edge <= 1'b1;
			port_0x1F7[7] <= 1'b1;
		end
		else if(port_0x1F7[7] & sd_load_valid)
			port_0x1F7 <= 8'h40;
		else
			sd_load_req_edge <= 1'b0;

		if(uart_rx_recv)
			port_0x3FD <= 8'h01;
		if(kbd_valid)
			kbd_stat <= 8'h01;

		if(ReadReq | WriteReq) begin
			DataValid <= 1'b1;
			if(ReadReq) begin
				if(port_addr == 32'h1F0) begin
					read_port <= port_0x1F0;
					sd_buf_addr <= sd_buf_addr + 1'b1;
				end
				else if(port_addr == 32'h1F7)
					read_port <= port_0x1F7;
				else if(port_addr == COM1 + 5) 
					read_port <= port_0x3FD;
				else if(port_addr == COM1) begin
					read_port <= uart_rx_data;
					port_0x3FD <= 8'h00;
				end
				else if(port_addr == KBSTATP) 
					read_port <= kbd_stat;
                else if(port_addr == KBDATAP) begin
					read_port <= kbd_data;
                    kbd_stat <= 8'h00;
                end
			end
			else if(WriteReq) begin
				case(port_addr)
					32'h1F2: port_0x1F2 <= write_data[7:0];
					32'h1F3: port_0x1F3 <= write_data[7:0];
					32'h1F4: port_0x1F4 <= write_data[7:0];
					32'h1F5: port_0x1F5 <= write_data[7:0];
					32'h1F6: port_0x1F6 <= write_data[7:0];
					32'h1F7: port_0x1F7 <= write_data[7:0];
					//COM1   : {uart_tx_start, uart_tx_data} <= {1'b1, write_data[7:0]};
					COM1   : begin
						{uart_tx_start, uart_tx_data} <= {1'b1, write_data[7:0]};
						$write("%c",write_data[7:0]);
					end
					TIMECMP_L: timecmp_L <= write_data;
					TIMECMP_H: timecmp_H <= write_data;
				endcase
			end
		end
		else 
			{DataValid, uart_tx_start} <= 2'b0;
	end

endmodule
