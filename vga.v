module VGA(
	input CLK,RST,
	input pck,
	input [12:0] ADDR,
	input WRITE,
	input [7:0] WRDATA,
	input [5:0] LINE,
	output reg [3:0]	vga_r,vga_g,vga_b,
	output vga_hs,vga_vs
);

`define VGA60x80;

wire [9:0]	hcnt,vcnt;
HVGEN HVGEN(pck,RST,vga_hs,vga_vs,hcnt,vcnt);

wire [6:0]	hchacnt = hcnt[9:3];
wire [2:0]	hdotcnt = hcnt[2:0];
wire [5:0]	vchacnt = vcnt[8:3];
wire [2:0]	vdotcnt = vcnt[2:0];

//vramaddr <- vcharcnt * 80 + hchacnt
//vramaddr <- vcharcnt * 64 + hchacnt
`ifdef VGA60x80
localparam VAddr_END = 60 * 80;
wire [15:0] tmp_vramaddr = (vchacnt<<6) + (vchacnt<<4) + hchacnt + (LINE << 6) + (LINE << 4);
`else
localparam VAddr_END = 60 * 64;
wire [15:0] tmp_vramaddr = (vchacnt<<6) + hchacnt + (LINE << 6);
`endif

wire [12:0] vramaddr = (tmp_vramaddr >= VAddr_END) ? tmp_vramaddr - VAddr_END : tmp_vramaddr;

reg [7:0]	sreg;
wire sregld = (hdotcnt == 3'h6 && hcnt < 10'd640);

wire [7:0]	cgout;
wire [7:0]	vramout;
//wire [11:0]	raddr = (VAddr_END > vramaddr) ? vramaddr : vramaddr - VAddr_END;
wire [12:0]	raddr = vramaddr;

vram	vram_inst (
	.clock ( CLK ),
	.data ( WRDATA ),
	.rdaddress ( raddr ),
	.wraddress ( ADDR ),
	.wren ( WRITE ),
	.q ( vramout )
	);

ascii_rom	ascii_rom_inst (
	.address ( {vramout[6:0],vdotcnt} ),
	.clock ( pck ),
	.q ( cgout )
	);

always @(posedge pck)	begin
	if(RST)
		sreg <= 8'h00;
	else if(sregld)
		sreg <= cgout;
	else
		sreg <= {sreg[6:0],1'b0};
end

wire [11:0] rgb = {4'h0, 4'hf, 4'h0};

`ifdef VGA60x80
wire hdispan = (10'd7 <= hcnt && hcnt < 10'd647);
`else
wire hdispan = (10'd7 <= hcnt && hcnt < 10'd519);
`endif
wire vdispan = (vcnt < 10'd480);

always @(posedge pck)	begin
	if(RST)
		{vga_r,vga_g,vga_b} <= 12'h000;
	else
		{vga_r,vga_g,vga_b} <= rgb & {12{hdispan & vdispan}} & {12{sreg[7]}};
		
end

endmodule
