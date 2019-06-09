module HVGEN(
	input pck,rst,
	output reg vga_hs,vga_vs,
	output reg [9:0]	hcnt,vcnt
);
/*
always @(posedge clk)	begin
	if(rst)
		pck <= 1'b0;
	else
		pck <= ~pck;
end
*/

parameter HMAX = 800;
wire hcntend = (hcnt == HMAX - 10'h001);

always @(posedge pck)	begin
	if(rst)
		hcnt <= 10'h000;
	else
	if(hcntend)
		hcnt <= 10'h000;
	else
		hcnt <= hcnt + 1'b1;
end

parameter VMAX = 525;

always @(posedge pck)	begin
	if(rst)
		vcnt <= 10'h000;
	else
	if(hcntend)	begin
		if(vcnt == VMAX - 10'h001)	
			vcnt <= 10'h000;
		else
			vcnt <= vcnt + 1'b1;
	end
end

//parameter HSSTART = 663;
//parameter HSEND = 759;
//parameter VSSTART = 449;
//parameter VSEND = 451;
parameter HSSTART = 655;
parameter HSEND = 751;
parameter VSSTART = 489;
parameter VSEND = 491;

always @(posedge pck)	begin
	if(rst)
		vga_hs <= 1'b1;
	else
	if(hcnt == HSSTART)
		vga_hs = 1'b0;
	else if(hcnt == HSEND)
		vga_hs = 1'b1;
end

always @(posedge pck)	begin
	if(rst)
		vga_vs <= 1'b1;
	else
	if(hcnt == HSSTART)	begin
		if(vcnt == VSSTART)	
			vga_vs = 1'b0;
		else if(vcnt == VSEND)
			vga_vs = 1'b1;
	end
end

//colorbar
/*
reg [9:0] count;
reg [2:0] color;
always @(posedge pck)	begin
	if(hcntend)	begin
		count <= 10'b0000000000;
		color <= 3'b000;
	end
	else begin
		 count <= count + 1'b1;	
		 if(count >= 10'd8 & count < 10'd648)	begin
			if(color[0] == 1'b0)	begin	
				vga_b <= vga_b + 1'b1;	
				vga_g <= 1'b0;	
				vga_r <= 1'b0;	
				if(vga_b == 3'b111)
					color[0] <= 1'b1;	
			end	
			else
			if(color[1] == 1'b0)	begin	
				vga_b <= 1'b0;	
				vga_g <= vga_g + 1'b1;	
				vga_r <= 1'b0;	
				if(vga_g == 3'b111)
					color[1] <= 1'b1;	
			end	
			else
			if(color[2] == 1'b0)	begin	
				vga_b <= 1'b0;	
				vga_g <= 1'b0;	
				vga_r <= vga_r + 1'b1;	
				if(vga_r == 3'b111)
					color[2] <= 1'b1;	
			end	
			else begin
				vga_b <= 4'b0000;
				vga_g <= 4'b0000;
				vga_r <= 4'b0000;
				color <= 3'b000;
			end
		end
		else	begin
				vga_b <= 4'b0000;
				vga_g <= 4'b0000;
				vga_r <= 4'b0000;
				color <= 3'b000;
		end
	end
end
*/
endmodule
