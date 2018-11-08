module CPU(
	input clk,reset,
	input [31:0] indata,
	output [31:0] outdata,
	//output [31:0] vaddr,
	output [31:0] addr,
	input MemValid,
	output ReadReq,
	output WriteReq,
	output [2:0] memsize,
	output [31:0] sd_sector,
	output sd_load_req,
	input sd_load_valid,
	output [8:0] sd_buf_addr,
	input [7:0] sd_data,
	input halt,
	output [7:0] uart_tx_data,
	output uart_tx_start,
	input [7:0] uart_rx_data,
	input uart_rx_recv,
    input kbd_valid,
    input [7:0] kbd_rddata,
	output [31:0] PC,
	output [31:0] a0
);
localparam IO_BASE = 32'hFFFFF000;
wire access_port = (vaddr >= IO_BASE);
wire [11:0] port_addr = vaddr - IO_BASE;

assign memsize = (cur_trans) ? 3'b010 : strb;
wire MULH;
wire [2:0] strb;
wire WenPC,WenInstr,WenRegfile;
wire WenCSR, WenRS2;
wire WenMem;
wire [2:0] ALUSrcACont;
wire [2:0] ALUSrcBCont;
wire [2:0] ImmCont;
wire [3:0] ALUCont;
wire [1:0] ResCont;
wire [6:0] Opcode;
wire [2:0] Funct3;
wire [6:0] Funct7;
wire ALUFlag;
wire [1:0] RunLevel;
wire read_req;
wire ECALL;
wire MRET;
wire INTR;
wire enintr;
//mmu
wire [31:0] vaddr, paddr;
wire [1:0] dummy;
wire [31:0] satp;
wire MMU_FAULT;
wire mmu_valid;
wire pte_read_req;
wire cur_trans;
wire [31:0] pte_addr;
wire TLB_refresh;
//wire [31:0] pte = (pte_read_req) ? indata : 32'hz;
wire [31:0] pte = indata;
wire pte_ready = (pte_read_req) ? DataValid : 1'b0;
wire start_trans_wr; 
wire start_trans_rd; 
wire start_trans = start_trans_wr | start_trans_rd; 
EDGE_TO_PULSE gen_trans_rd(clk, read_req & ~access_port, start_trans_rd);
EDGE_TO_PULSE gen_trans_wr(clk, WenMem & ~access_port, start_trans_wr);

wire start_port_wr; 
wire start_port_rd; 
//wire start_port = start_port_wr | start_port_rd; 
EDGE_TO_PULSE gen_port_rd(clk, read_req & access_port, start_port_rd);
EDGE_TO_PULSE gen_port_wr(clk, WenMem & access_port, start_port_wr);

assign addr = (pte_read_req) ? pte_addr : paddr;
assign ReadReq = (mmu_valid & read_req) | pte_read_req;
assign WriteReq = mmu_valid & WenMem;

//PORT
wire [31:0] port_rd_data;
wire port_data_valid;
wire [63:0] mtimecmp;
wire [31:0] RdData = (access_port) ? port_rd_data : indata;
wire DataValid = (access_port) ? port_data_valid : MemValid;

DATAPATH datapath(
	.clk(clk),
	.reset(reset),
	.indata(RdData),
	.addr(vaddr), 
	.wrdata(outdata),
	.WenPC(WenPC),
	.WenInstr(WenInstr),
	.WenRegfile(WenRegfile),
	.WenCSR(WenCSR),
	.WenRS2(WenRS2),
	.AddrSrcCont(AddrSrcCont),
	.ALUSrcACont(ALUSrcACont),
	.ALUSrcBCont(ALUSrcBCont),
	.ImmCont(ImmCont),
	.ALUCont(ALUCont),
	.ResCont(ResCont),
	.Opcode(Opcode),
	.Funct3(Funct3),
	.Funct7(Funct7),
	.ALUFlag(ALUFlag),
	.RunLevel(RunLevel),
	.satp(satp),
	.uart_rx_recv(uart_rx_recv),
    .kbd_valid(kbd_valid),
	.MULH(MULH),
	.ECALL(ECALL),
	.MRET(MRET),
	.INTR(INTR),
	.enintr(enintr),
	.mtimecmp(mtimecmp),
    .TLB_refresh(TLB_refresh),
	.PC(PC),
	.a0(a0)
);

CONTROLLER controller(
	.clk(clk),
	.reset(reset),
	.Opcode(Opcode),
	.Funct3(Funct3),
	.Funct7(Funct7),
	.WenPC(WenPC),
	.WenInstr(WenInstr),
	.WenRegfile(WenRegfile),
	.WenMem(WenMem),
	.WenCSR(WenCSR),
	.WenRS2(WenRS2),
	.AddrSrcCont(AddrSrcCont),
	.ALUSrcACont(ALUSrcACont),
	.ALUSrcBCont(ALUSrcBCont),
	.ImmCont(ImmCont),
	.ALUCont(ALUCont),
	.ResCont(ResCont),
	.ALUFlag(ALUFlag),
	.MemStrb(strb),
	.RunLevel(RunLevel),
	.DataValid(DataValid & ~cur_trans),
	.read_req(read_req),
	.MULH(MULH),
	.ECALL(ECALL),
	.MRET(MRET),
	.INTR(INTR),
	.halt(halt),
	.enintr(enintr)
);

MMU mmu(
	.clk(clk),
	.reset(reset),
	.va(vaddr),
	.satp(satp),
	.pa({dummy, paddr}),
	.valid(mmu_valid),
	.Fault(MMU_FAULT),
	.rd_req(pte_read_req),
	.pte_addr(pte_addr),
	.pte_buf(pte),
	.data_ready(pte_ready),
	.start_trans(start_trans),
    .TLB_refresh(TLB_refresh),
	.trans(cur_trans)
);

PORT port(
	.clk(clk),
	.reset(reset),
	.port_addr(port_addr),
	.ReadReq(start_port_rd),
	.WriteReq(start_port_wr),
	.read_data(port_rd_data),
	.write_data(outdata),
	.DataValid(port_data_valid),
	.sd_sect(sd_sector),
	.sd_load_req(sd_load_req),
	.sd_load_valid(sd_load_valid),
	.sd_buf_addr(sd_buf_addr),
	.sd_data(sd_data),
	.uart_tx_data(uart_tx_data),
	.uart_tx_start(uart_tx_start),
	.uart_rx_data(uart_rx_data),
	.uart_rx_recv(uart_rx_recv),
    .kbd_valid(kbd_valid),
    .kbd_data(kbd_rddata),
	.mtimecmp(mtimecmp)
);

endmodule
