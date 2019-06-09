`timescale 1ps/1ps

module testbench();

localparam SECTSIZE = 512;

//clk:80MHz		spi_clk:200kHz		spi_clk_high:20MHz
reg clk,reset;
reg spi_clk;
reg spi_clk_high;
reg [31:0] mem_out;
wire [31:0] mem_in,mem_addr;
wire [2:0] mem_size;
reg [31:0] RAM[3000000:0];
reg [31:0] SD[3000000:0];
reg [7:0] spi_RAM[511:0];
wire [31:0] spi_MemReadData;
wire [31:0] indata = mem_out;
reg mem_read;

reg mem_read_valid;
reg mem_write_valid;
wire addrsrc;
wire WriteReq;
wire ReadReq;
wire DataValid = mem_read_valid | mem_write_valid;
wire [31:0] sd_sector;
wire sd_load_req;
reg sd_load_valid;
wire [8:0] sd_buf_addr;
reg [7:0] sd_data;
reg sd_data_valid;

CPU cpu(
	.clk(clk),
	.reset(reset),
	.indata(indata),
	.outdata(mem_in),
	.addr(mem_addr),
	.WriteReq(WriteReq),
	.ReadReq(ReadReq),
	.memsize(mem_size),
	.MemValid(DataValid),
	.sd_sector(sd_sector),
	.sd_load_req(sd_load_req),
	.sd_load_valid(sd_load_valid),
	.sd_buf_addr(sd_buf_addr),
	.sd_data(sd_data),
	.halt(1'b0)
);

always @(posedge clk)
	if(reset)
		mem_read_valid <= 1'b0;
	else if(ReadReq) begin
		mem_read_valid <= 1'b1;
		case(mem_size)
			3'b000:
				if(mem_addr[1:0] == 2'b00) mem_out <= {{24{RAM[mem_addr >> 2][7]}},RAM[mem_addr >> 2][7:0]};
				else if(mem_addr[1:0] == 2'b01) mem_out <= {{24{RAM[mem_addr >> 2][15]}},RAM[mem_addr >> 2][15:8]};
				else if(mem_addr[1:0] == 2'b10) mem_out <= {{24{RAM[mem_addr >> 2][23]}},RAM[mem_addr >> 2][23:16]};
				else if(mem_addr[1:0] == 2'b11) mem_out <= {{24{RAM[mem_addr >> 2][31]}},RAM[mem_addr >> 2][31:24]};
			3'b001:
				if(mem_addr[1] == 1'b0) mem_out <= {{16{RAM[mem_addr >> 2][15]}},RAM[mem_addr >> 2][15:0]};
				else  mem_out <= {{16{RAM[mem_addr >> 2][31]}},RAM[mem_addr >> 2][31:16]};
			3'b010:	mem_out <= RAM[mem_addr >> 2];
			3'b100:
				if(mem_addr[1:0] == 2'b00) mem_out <= {24'h0,RAM[mem_addr >> 2][7:0]};
				else if(mem_addr[1:0] == 2'b01) mem_out <= {24'h0,RAM[mem_addr >> 2][15:8]};
				else if(mem_addr[1:0] == 2'b10) mem_out <= {24'h0,RAM[mem_addr >> 2][23:16]};
				else if(mem_addr[1:0] == 2'b11) mem_out <= {24'h0,RAM[mem_addr >> 2][31:24]};
			3'b101:
				if(mem_addr[1] == 1'b0) mem_out <= {16'h0,RAM[mem_addr >> 2][15:0]};
				else  mem_out <= {16'h0,RAM[mem_addr >> 2][31:16]};
			default:mem_out <= 32'h0;
		endcase
	end
	else
		mem_read_valid <= 1'b0;

always @(posedge clk)
	if(reset)
		mem_write_valid <= 1'b0;
	else if(WriteReq) begin
		mem_write_valid <= 1'b1;
		case(mem_size)
			3'b000:
				if(mem_addr[1:0] == 2'b00) RAM[mem_addr >> 2][7:0] <= mem_in[7:0];
				else if(mem_addr[1:0] == 2'b01) RAM[mem_addr >> 2][15:8] <= mem_in[7:0];
				else if(mem_addr[1:0] == 2'b10) RAM[mem_addr >> 2][23:16] <= mem_in[7:0];
				else if(mem_addr[1:0] == 2'b11) RAM[mem_addr >> 2][31:24] <= mem_in[7:0];
			3'b001:
				if(mem_addr[1] == 1'b0) RAM[mem_addr >> 2][15:0] <= mem_in[15:0];
				else if(mem_addr[1] == 1'b1) RAM[mem_addr >> 2][31:16] <= mem_in[15:0];
			3'b010:
				RAM[mem_addr >> 2] <= mem_in;
		endcase
	end
	else
		mem_write_valid <= 1'b0;

integer k;
//assign sd_data = spi_RAM[sd_buf_addr];
always @(posedge spi_clk_high)
	sd_data <= spi_RAM[sd_buf_addr];

always @(posedge clk)
	if(sd_load_req) begin
		for(k = 0; k < 512; k = k + 4) begin
			spi_RAM[k] <= SD[(SECTSIZE*sd_sector+k)/4][7:0];
			spi_RAM[k+1] <= SD[(SECTSIZE*sd_sector+k)/4][15:8];
			spi_RAM[k+2] <= SD[(SECTSIZE*sd_sector+k)/4][23:16];
			spi_RAM[k+3] <= SD[(SECTSIZE*sd_sector+k)/4][31:24];
		end
		sd_load_valid <= 1'b1;
	end
	else
		sd_load_valid <= 1'b0;


//////////////////////////////////////////////////
///////SIMULATION
/////////////////////////////////////////////////
reg start;
reg start_sd;
integer i;
initial begin
	$readmemh("sd_card.hex", SD);
	$readmemh("test.hex", RAM);
	$dumpfile("wave.vcd");
	$dumpvars(0,testbench);
	for(i = 0; i < 32; i = i+1) begin
		$dumpvars(0,cpu.datapath.regfile.x[i]);
	end
	//	$dumpvars(0,RAM[(16*16 + 3*16 + 8) >> 2]);
	//for(i = 32'h7d00; i < 32'h7c00 + 32; i = i+1) 
	//	$dumpvars(0,RAM[i / 4]);
	//$dumpvars(0,RAM[32'h7d08 / 4]);
	//$display("%08x",RAM[0]);
/*
	$monitor("PC : %08x\nra = %08x, sp = %08x, s0 = %08x, s1 = %08x\na0 = %08x, a1 = %08x, a2 = %08x, a3 = %08x\na4 = %08x, a5 = %08x, a6 = %08x, a7 = %08x\n",
					cpu.datapath.PC,
					cpu.datapath.regfile.x[1],cpu.datapath.regfile.x[2],
					cpu.datapath.regfile.x[8],cpu.datapath.regfile.x[9],
					cpu.datapath.regfile.x[10],cpu.datapath.regfile.x[11],
					cpu.datapath.regfile.x[12],cpu.datapath.regfile.x[13],
					cpu.datapath.regfile.x[14],cpu.datapath.regfile.x[15],
					cpu.datapath.regfile.x[16],cpu.datapath.regfile.x[17]);
*/
	$monitor("PC : %08x",cpu.datapath.PC);
	clk <= 1'b0;
	spi_clk <= 1'b0;
	spi_clk_cnt <= 0;
	spi_clk_high <= 1'b0;
	spi_clk_high_cnt <= 0;
	reset <= 1'b0;
	start <= 1'b0;
	start_sd <= 1'b0;

	#50
	reset <= 1'b1;

	#50
	reset <= 1'b0;
	start <= 1'b1;
end

always #5
	clk <= ~clk;

reg [31:0] spi_clk_cnt;
always @(posedge clk) begin
	spi_clk_cnt <= spi_clk_cnt + 1'b1;
	if(spi_clk_cnt == 200) begin
		spi_clk <= ~spi_clk;
		spi_clk_cnt <= 0;
	end
end
reg [31:0] spi_clk_high_cnt;
always @(posedge clk) begin
	spi_clk_high_cnt <= spi_clk_high_cnt + 1'b1;
	if(spi_clk_high_cnt == 2) begin
		spi_clk_high <= ~spi_clk_high;
		spi_clk_high_cnt <= 0;
	end
end

reg [31:0] prev_PC[2:0];
reg record_start;
always @(posedge clk)
	if(reset)
		record_start <= 1'b0;
	else if(start) begin
		//$display("%08x",cpu.datapath.PC);
		if(start_sd == 1'b0 && cpu.datapath.PC == 32'h7c00) begin
			start_sd <= 1'b1;
			//$display("OK");
		end
		if(cpu.datapath.PC == 32'h0 && record_start == 1'b0 && start_sd == 1'b1) begin
			$dumpfile("wave.vcd");
			$dumpvars(0,testbench);
			for(i = 0; i < 32; i = i+1) begin
				$dumpvars(0,cpu.datapath.regfile.x[i]);
			end
			record_start <= 1'b1;
		end
		//if(prev_PC[2] == cpu.datapath.PC && prev_PC[2] == prev_PC[1] & prev_PC[0]) begin
		if(cpu.mmu.Fault | (cpu.datapath.InstrFault && cpu.datapath.PC != 32'h0)) begin
			$display(" ra = %08x, sp = %08x, s0 = %08x, s1 = %08x   ",
				cpu.datapath.regfile.x[1],cpu.datapath.regfile.x[2],
				cpu.datapath.regfile.x[8],cpu.datapath.regfile.x[9]);
			$display(" a0 = %08x, a1 = %08x, a2 = %08x, a3 = %08x   ",
				cpu.datapath.regfile.x[10],cpu.datapath.regfile.x[11],
				cpu.datapath.regfile.x[12],cpu.datapath.regfile.x[13]);
			$display(" a4 = %08x, a5 = %08x, a6 = %08x, a7 = %08x   ",
				cpu.datapath.regfile.x[14],cpu.datapath.regfile.x[15],
				cpu.datapath.regfile.x[16],cpu.datapath.regfile.x[17]);
			for(i = 0; i < 23; i = i+1)
				$display("%08x",RAM[(32'hF00 >> 2) + i]);
			$finish;
		end                                                                                                                                                                              
	end                                                                                                                                                                                      

localparam LIMIT = 1000000;
reg [31:0] disp_cnt;
always @(posedge clk, posedge reset)
	if(reset)		
		disp_cnt <= 32'h0;
	else begin
		disp_cnt <= disp_cnt + 1'b1;                                                                                                                                                     
		if(disp_cnt == LIMIT) begin                                                                                                                                                      
			prev_PC[0] <= cpu.datapath.PC;                                                                                                                                           
			prev_PC[1] <= prev_PC[0];                                                                                                                                                
			prev_PC[2] <= prev_PC[1];                                                                                                                                                
			$display("%08x",cpu.datapath.PC);  
			disp_cnt <= 32'h0;
		end
	end


endmodule
