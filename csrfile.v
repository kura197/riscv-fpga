module CSRFILE(
	input clk,reset,
	input [11:0] csr,
	input wren,
	output reg [1:0] runlevel,
	input [31:0] indata,
	output reg [31:0] outdata,
	output reg [31:0] satp,
	input [63:0] mtimecmp,
	input ECALL,
	input MRET,
	input INTR,
	input uart_rx_recv,
    input kbd_valid,
	output enintr,
    output TLB_refresh,
	output Fault
);
localparam U = 2'h0;
localparam M = 2'h3;

reg[31:0] mstatus;
reg[31:0] medeleg;
reg[31:0] mideleg;
reg[31:0] mtvec;
reg[31:0] mscratch;
reg[31:0] mepc;
reg[31:0] mcause;
reg[31:0] mip;
reg[31:0] mie;
reg[63:0] mtime;

wire soft_intr = mip[3] & mie[3];
wire timer_intr = mip[7] & mie[7];
wire ext_intr = mip[11] & mie[11];
wire [2:0] intr = {3{mstatus[3]}} & {soft_intr,timer_intr,ext_intr};
assign enintr = |intr;
reg timeintr;
reg read_fault, write_fault;
assign Fault = read_fault | write_fault;
reg [30:0] ex_code;
assign TLB_refresh = wren & (csr == 12'h180);
reg kbd_pend;

always @(posedge clk)
    if(reset)   kbd_pend <= 1'b0;
    else if(kbd_valid) kbd_pend <= 1'b1;
    else if(INTR) kbd_pend <= 1'b0;

always @*
	if(runlevel == U) begin
		if(soft_intr)
			ex_code = 31'd0;
		else if(timer_intr)
			ex_code = 31'd4;
		else if(ext_intr)
			ex_code = 31'd8 + kbd_pend;
		else
			ex_code = 31'd0;
	end
	else if(runlevel == M) begin
		if(soft_intr)
			ex_code = 31'd3;
		else if(timer_intr)
			ex_code = 31'd7;
		else if(ext_intr)
			ex_code = 31'd11 + kbd_pend;
		else
			ex_code = 31'd0;
	end
	else
			ex_code = 31'd0;
	

always @* begin
	read_fault <= 1'b0;
	if(ECALL | INTR)
		outdata <= {mtvec[31:2], 2'h0};
	else if(MRET)
		outdata <= mepc;
	else
		case(csr)
			12'h300: outdata <= mstatus;
			12'h302: outdata <= medeleg;
			12'h303: outdata <= mideleg;
			12'h304: outdata <= mie;
			12'h305: outdata <= mtvec;
			12'h340: outdata <= mscratch;
			12'h341: outdata <= mepc;
			12'h342: outdata <= mcause;
			12'h344: outdata <= mip;
			12'h180: outdata <= satp;
			default: {read_fault,outdata} <= {1'b1,32'h0};
		endcase
	end

always @(posedge clk, posedge reset)
	if(reset) begin
		mstatus <= 32'h0;
		medeleg <= 32'h0;
		mideleg <= 32'h0;
		mie <= 32'h0;
		mtvec <= 32'h0;
		mscratch <= 32'h0;
		mepc <= 32'h0;
		mcause <= 32'h0;
		mip <= 32'h0;
		satp <= 32'h0;
		write_fault <= 1'b0;
		runlevel <= M;
	end
	else if(wren)
		if(ECALL) begin
			mepc <= indata; 
			mcause <= (runlevel == U) ? 32'd8 : 32'd11;
			mstatus[12:11] <= runlevel;
			mstatus[7] <= mstatus[3];
			mstatus[3] <= 1'b0;
			runlevel <= M;
		end
		else if(INTR) begin
			mepc <= indata; 
			mcause[31] <= 1'b1;
			mcause[30:0] <= ex_code;
			mstatus[12:11] <= runlevel;
			mstatus[7] <= mstatus[3];
			mstatus[3] <= 1'b0;
			runlevel <= M;
		end
		else
			case(csr)
				12'h300: mstatus <= indata;
				12'h302: medeleg <= indata;
				12'h303: mideleg <= indata;
				12'h304: mie <= indata;
				12'h305: mtvec <= indata;
				12'h340: mscratch <= indata;
				12'h341: mepc <= indata;
				12'h342: mcause <= indata;
				12'h344: mip <= indata;
				12'h180: satp <= indata;
				default: write_fault <= 1'b1;
			endcase
	else if(MRET) begin
		runlevel <= mstatus[12:11];
		mstatus[12:11] <= U;
		mstatus[3] <= mstatus[7];
		mstatus[7] <= 1'b1;
	end 
	else if(uart_rx_recv | kbd_valid)
		mip[11] <= 1'b1;
	else if(timeintr) 
		mip[7] <= 1'b1;

always @(posedge clk, posedge reset)
	if(reset) begin
		mtime <= 64'h0;
		timeintr <= 1'b0;
	end
	else if(mip[7]) begin
		timeintr <= 1'b0;
		mtime <= 64'h0;
	end
	else if(mtime >= mtimecmp)
		timeintr <= 1'b1;
	else
		mtime <= mtime + 1'b1;

endmodule
