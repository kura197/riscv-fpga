module RISCV(
	input clk,
	input spi_clk,
	input spi_clk_normal,
	input reset,
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N,
	output DRAM_CKE,
	output DRAM_CLK,
	output DRAM_CS_N,
	inout [15:0] DRAM_DQ,
	output DRAM_LDQM,
	output DRAM_RAS_N,
	output DRAM_UDQM,
	output DRAM_WE_N,
	input CLK_SPI,
	output SCK,
	output MOSI,
	input MISO,
	output CS,
	output TXD,
	input RXD,
	input pck,
	output [3:0] vga_r,vga_g,vga_b,
	output vga_hs,vga_vs,
    input KBD_CLK,
    input KBD_INDATA,
	output [31:0] PC
);

wire DRAM_Init;
wire DRAM_RdValid;
wire DRAM_WrValid;

wire [31:0] RdData;
wire [31:0] WrData;
wire [31:0] MemAddr;
wire MemWrReq,MemRdReq;
wire [2:0] MemSize;
wire MemDataValid;
wire halt;
wire [31:0] SDSector;
wire SDLoadReq;
reg SDLoadReqPend;
wire SDLoadValid;
wire [8:0] SDBufAddr;
wire [7:0] SDData;
wire [7:0] UART_TX_Data;
wire [7:0] UART_RX_Data;
wire UART_TX_Send;
wire UART_RX_Recv;
wire TX_BUSY;
wire RX_BUSY;
wire vga_init;
wire kbd_valid;
wire [7:0] kdb_rddata;

assign MemDataValid = DRAM_RdValid | DRAM_WrValid;
assign halt = ~DRAM_ROM_Init | ~SD_Init | ~vga_init;
CPU cpu(
	.clk(clk),
	.reset(reset),
	.indata(RdData),
	.outdata(WrData),
	.addr(MemAddr),
	.WriteReq(MemWrReq),
	.ReadReq(MemRdReq),
	.memsize(MemSize),
	.MemValid(MemDataValid),
	.sd_sector(SDSector),
	.sd_load_req(SDLoadReq),
	.sd_load_valid(SDLoadValid),
	.sd_buf_addr(SDBufAddr),
	.sd_data(SDData),
	.uart_tx_data(UART_TX_Data),
	.uart_tx_start(UART_TX_Send),
	.uart_rx_data(UART_RX_Data),
	.uart_rx_recv(UART_RX_Recv),
    .kbd_valid(kbd_valid),
    .kbd_rddata(kbd_rddata),
	.halt(halt),
	.PC(PC)
);

UART uart(
	.RESETB(~reset), 
	.CLK(clk),
	.TXD(TXD),
	.RXD(RXD),
	.TX_DATA(UART_TX_Data),
	.TX_DATA_EN(UART_TX_Send),
	.TX_BUSY(TX_BUSY),
	.RX_DATA(UART_RX_Data),
	.RX_DATA_EN(UART_RX_Recv),
	.RX_BUSY(RX_BUSY)
);

PS2 kbd(
    .SampleCLK(clk),
    .RST(reset),
    .InCLK(KBD_CLK),
    .InData(KBD_INDATA),
    .Valid(kbd_valid),
    .Ascii(kbd_rddata)
);


VGA_CONTROLLER vga(
	.CLK(clk),
	.RST(reset),
	.pck(pck),
	.VData(UART_TX_Data),
	.Wen(UART_TX_Send),
    .vga_init(vga_init),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b),
	.vga_hs(vga_hs),
	.vga_vs(vga_vs)
);


wire SD_Init;
SD_SPI_TOP sd(
	//200kHz
	.CLK_init(spi_clk),
	.CLK_RAM(clk),
	.CLK_normal(spi_clk_normal),
	.RST(reset),
	.SCK(SCK),
	.MOSI(MOSI),
	.MISO(MISO),
	.CS(CS),
	.init_end(SD_Init),
	.addr(SDSector),
	.read_req(SDLoadReqPend),
	.recv_block_valid(SDLoadValid),
	.spi_ram_output(SDData),
	.spi_ram_rd_addr(SDBufAddr)
);
reg pre_spi_clk;
always @(posedge clk) begin
	pre_spi_clk <= spi_clk_normal;
	if(SDLoadReq)
		SDLoadReqPend <= 1'b1;
	else if(spi_clk_normal & ~pre_spi_clk)
		SDLoadReqPend <= 1'b0;
end

reg MemWrReqPend;
reg MemRdReqPend;
always @(posedge clk, posedge reset) 
	if(reset) begin
		MemWrReqPend <= 1'b0;
		MemRdReqPend <= 1'b0;
	end
	else if(DRAM_RdValid | DRAM_WrValid) begin
		if(DRAM_WrValid)
			MemWrReqPend <= 1'b0;
		if(DRAM_RdValid)
			MemRdReqPend <= 1'b0;
	end
	else if(MemRdReq | MemWrReq) begin
		if(MemWrReq)
			MemWrReqPend <= 1'b1;
		if(MemRdReq)
			MemRdReqPend <= 1'b1;
	end

wire SDRAM_WrReq = (DRAM_ROM_Init) ? MemWrReqPend : ROM_WrReq;
wire [31:0] SDRAM_Addr = (DRAM_ROM_Init) ? MemAddr : {22'h0, ROM_Addr, 2'h0};
wire [31:0] SDRAM_WrData = (DRAM_ROM_Init) ? WrData : ROM_Data;
wire [2:0] SDRAM_MemSize = (DRAM_ROM_Init) ? MemSize : 3'b010;
SDRAM_RISCV sdram(
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
	.rd_req_buf(MemRdReqPend),
	.wr_req_buf(SDRAM_WrReq),
	.mem_addr(SDRAM_Addr),
	.indata(SDRAM_WrData),
	.outdata(RdData),
	.init(DRAM_Init),
	.rd_valid(DRAM_RdValid),
	.wr_valid(DRAM_WrValid),
	.mem_size(SDRAM_MemSize)
);

reg [7:0] ROM_Addr;
wire [31:0] ROM_Data;
reg DRAM_ROM_Init;
reg [1:0] ROM_state;
reg ROM_WrReq;
wire clk_rev = ~clk;
rom	ROM (
	.address ( ROM_Addr ),
	.clock ( clk_rev ),
	.q ( ROM_Data )
	);

always @(posedge clk, posedge reset)
	if(reset) begin
		ROM_Addr <= 8'hff;
		DRAM_ROM_Init <= 1'b0;
		ROM_state <= 2'b0;
		ROM_WrReq <= 2'b0;
	end
	else if(DRAM_Init & ~DRAM_ROM_Init) begin
		case(ROM_state)
			2'h0:begin
				ROM_Addr <= ROM_Addr + 1'b1;
				ROM_state <= 2'h1;
			end
			2'h1:begin
				ROM_WrReq <= 1'b1;
				ROM_state <= 2'h2;
			end
			2'h2:if(ROM_Addr == 8'hff) ROM_state <= 2'h3;
				 //else if(DRAM_WrValid)	ROM_state <= 2'h0;
				 else if(DRAM_WrValid)	{ROM_WrReq, ROM_state} <= 3'h0;
				 //else	{ROM_WrReq, ROM_state} <= 3'b010;
				 else	ROM_state <= 2'h2;
			2'h3: DRAM_ROM_Init <= 1'b1;
		endcase
	end


endmodule
