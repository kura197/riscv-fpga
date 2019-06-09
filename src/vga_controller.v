module VGA_CONTROLLER(
	input CLK,RST,
	input pck,
	input [7:0] VData,
	input Wen,
    output reg vga_init,
	output [3:0] vga_r,vga_g,vga_b,
	output vga_hs,vga_vs
);

`define VGA60x80;

`ifdef VGA60x80
localparam ROW = 60;
localparam COL = 80;
reg [7:0] cnt;
`else
localparam ROW = 60;
localparam COL = 64;
`endif
localparam VAddr_END = ROW * COL;

//60 * 64 ??
reg [12:0] VAddr;
wire [12:0] VramAddr;
reg WRITE;
reg [7:0] WRDATA;
reg [5:0] LINE;
reg scroll;
wire BS = (VData == 8'h08);
//wire HT = (VData == 8'h09);
wire LF = (VData == 8'hA);
wire EN = (VData >= 8'h20 & VData <= 8'h7d);
localparam SPACE = 8'h20;
reg [5:0] last_LINE;
reg delete_LINE;
reg BS_flag;

//assign VramAddr = (BS & VAddr[5:0] != 6'h0) ? VAddr - 1'b1 : VAddr;
assign VramAddr = VAddr;

VGA vga(
	.CLK(CLK),
	.RST(RST),
	.pck(pck),
	.ADDR(VramAddr),
	.WRITE(WRITE),
	.WRDATA(WRDATA),
	.LINE(LINE),
	.vga_r(vga_r),
	.vga_g(vga_g),
	.vga_b(vga_b),
	.vga_hs(vga_hs),
	.vga_vs(vga_vs)
);

wire [12:0] next_vaddr = (VAddr / COL) + 1'b1;
always @(posedge CLK, posedge RST) 
	if(RST) begin
		VAddr <= 12'h0;
		WRITE <= 1'b0;
		WRDATA <= 8'h0;
		LINE <= 6'h0;
        last_LINE <= 6'h0;
		scroll <= 1'b0;
        vga_init <= 1'b0;
        delete_LINE <= 1'b0;
        BS_flag <= 1'b0;
	end
    else if(~vga_init) 
        if(VAddr < VAddr_END) begin
            WRITE <= 1'b1;
            WRDATA <= SPACE;
            VAddr <= VAddr + 1'b1;
        end
        else begin
            VAddr <= 12'h0;
            vga_init <= 1'b1;
        end
    else if(delete_LINE) 
`ifdef VGA60x80
        if(cnt < COL) begin
            WRITE <= 1'b1;
            WRDATA <= SPACE;
            VAddr <= VAddr + 1'b1;
            cnt <= cnt + 1'b1;
        end
        else begin
            VAddr <= ((last_LINE - 1'b1) << 6) + ((last_LINE - 1'b1) << 4) - 1'b1;
            delete_LINE <= 1'b0;
        end
`else
        if(VAddr[5:0] != (COL - 1)) begin
            WRITE <= 1'b1;
            WRDATA <= SPACE;
            VAddr <= VAddr + 1'b1;
        end
        else begin
            VAddr <= ((last_LINE - 1'b1) << 6) - 1'b1;
            delete_LINE <= 1'b0;
        end
`endif
	else if(Wen) begin
		if(BS) begin
			//VAddr <= (VAddr == 12'h0) ? VAddr : VAddr - 1'b1;
            BS_flag <= 1'b1;
			WRITE <= 1'b1;
			WRDATA <= SPACE;
		end
		else if(LF) begin
			if(scroll)
				LINE <= (LINE == (ROW - 1)) ? 6'h0 : LINE + 1'b1;
`ifdef VGA60x80
			VAddr <= (next_vaddr<<6) + (next_vaddr<<4) - 1'b1;
`else
			VAddr <= ((VAddr + COL) & 12'hFC0) - 1'b1;
`endif
		end
		else if(EN) begin
			VAddr <=  VAddr + 1'b1;
            //要改善
			//if(VAddr[5:0] == 6'h3f & scroll)
`ifdef VGA60x80
			if(VAddr % COL == (COL - 2) & scroll)
				LINE <= (LINE == (ROW - 1)) ? 6'h0 : LINE + 1'b1;
`else
			if(VAddr[5:0] == (COL - 2) & scroll)
				LINE <= (LINE == (ROW - 1)) ? 6'h0 : LINE + 1'b1;
`endif
			WRITE <= 1'b1;
			WRDATA <= VData;
		end
		if(VAddr >= VAddr_END) begin
			scroll <= 1'b1;
			VAddr <= 12'h0;
			LINE <= 1'b1;
		end
	end
    else begin
		WRITE <= 1'b0;
        last_LINE <= LINE;
        if(BS_flag) begin
			VAddr <= (VAddr == 12'h0) ? VAddr : VAddr - 1'b1;
            BS_flag <= 1'b0;
        end
        if(last_LINE != LINE) begin
            delete_LINE <= 1'b1;
            WRITE <= 1'b1;
            WRDATA <= SPACE;
`ifdef VGA60x80
            VAddr <= (last_LINE << 6) + (last_LINE << 4);
            cnt <= 7'h0;
`else
            VAddr <= (last_LINE << 6);
`endif
        end
    end

endmodule
