module MMU(
	input clk,reset,
	input [31:0] va,
	input [31:0] satp,
	output reg [33:0] pa,
	output valid,
	output reg Fault,
	output reg rd_req,
	output reg [31:0] pte_addr,
	input [31:0] pte_buf,
	input data_ready,
	input start_trans,
    input TLB_refresh,
	output reg trans
);

localparam PAGESIZE = 4096;
localparam PAGESHIFT = 12;
localparam PTESIZE = 4;
localparam PTESHIFT = 2; 
//localparam [31:0] IO_BASE = 32'hFFFFF000;

wire MODE = satp[31];
//wire access_port = (va >= IO_BASE);
wire [9:0] VPN1 = va[31:22];
wire [9:0] VPN0 = va[21:12];
wire [11:0] offset = va[11:0];
reg i;
reg [31:0] pte;
wire [31:0] mem = pte;
wire [21:0] mem_entry = mem[31:10];
wire [21:0] entry = i ? satp[21:0] : mem_entry;
wire [34:0] a = {12'h0, entry} << PAGESHIFT;
reg find_pte;
wire [11:0] ppn1 = pte[31:20];
wire [9:0] ppn0 = (i) ? VPN0 : pte[19:10];
reg valid_edge;
EDGE_TO_PULSE #(1,1) e2p(clk, valid_edge, valid);

//TLB
//0 - 21 : {PPN1, PPN0}
//22 - 43 : {VPN1, VPN0}
//44 : active flag
reg [45:0] TLB[7:0];
reg [2:0] TLB_idx;
reg TLB_hit;
reg [2:0] TLB_hit_idx;
integer k;

always @*
    case({1'b1, VPN1, VPN0})
        TLB[0][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h0};
        TLB[1][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h1};
        TLB[2][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h2};
        TLB[3][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h3};
        TLB[4][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h4};
        TLB[5][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h5};
        TLB[6][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h6};
        TLB[7][44:22]:  {TLB_hit, TLB_hit_idx} <= {1'b1, 3'h7};
        default:{TLB_hit, TLB_hit_idx} <= 4'h0;
    endcase

always @(posedge clk, posedge reset)
	if(reset) begin
		i <= 1'b1;
		valid_edge <= 1'b0;
		rd_req <= 1'b0;
		Fault <= 1'b0;
		find_pte <= 1'b0;
        TLB_idx <= 3'h0;
        for(k = 0; k < 8; k = k + 1)
            TLB[k][44] <= 1'b0;
	end
	else if(Fault) 
		Fault <= 1'b1;
    else if(TLB_refresh)
        for(k = 0; k < 8; k = k + 1)
            TLB[k][44] <= 1'b0;
	else if(start_trans)
		trans <= 1'b1;
	else if(trans) begin
		if(~MODE) begin
			valid_edge <= 1'b1;
			pa <= va;
			rd_req <= 1'b0;
			Fault <= 1'b0;
			trans <= 1'b0;
		end
        else if(TLB_hit) begin
			pa <= {TLB[TLB_hit_idx][21:0], offset};
			valid_edge  <= 1'b1;
			trans <= 1'b0;
        end
		else if(find_pte) begin
			pa <= {ppn1, ppn0, offset};
            TLB[TLB_idx] <= {1'b1, VPN1, VPN0, ppn1, ppn0};
            TLB_idx <= TLB_idx + 1'b1;
			valid_edge  <= 1'b1;
			find_pte <= 1'b0;
			i <= 1'b1;
			trans <= 1'b0;
		end
		else if(~rd_req) begin
			valid_edge <= 1'b0;
			Fault <= 1'b0;
			pte_addr <= (i) ? a + (VPN1 << PTESHIFT) : a + (VPN0 << PTESHIFT);
			rd_req <= 1'b1;
		end
		else if(data_ready) begin
			rd_req <= 1'b0;
			pte <= pte_buf;
			if(~pte_buf[0] || (~pte_buf[1] & pte_buf[2]))
				Fault <= 1'b1;
			else if(pte_buf[1] | pte_buf[3])
				find_pte <= 1'b1;
			else 
				i <= i - 1'b1;
		end
	end
	else
		valid_edge <= 1'b0;

endmodule
