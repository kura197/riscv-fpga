module REGFILE #(parameter INITIAL_SP = 32'hff)(
	input  clk,reset,
	input  we,
	input [4:0] ra1,ra2,wa,
	input [31:0] wd,
	output [31:0] rs1,rs2,
	output [31:0] a0
);

reg [31:0] x[31:0];
assign a0 = x[10];
//integer i;

always @(posedge clk, posedge reset) 
	if(reset) begin
		x[0] <= 32'h0;
		//x[1] <= 32'h0;
		x[2] <= INITIAL_SP;
		//for(i = 3; i < 32; i = i + 1)
		//	x[i] <= 32'h0;
	end
	else if(we)
		x[wa] <= wd;
	else
		x[0] <= 32'h0;

assign rs1 = (ra1 != 5'h0) ? x[ra1] : 32'h0;
assign rs2 = (ra2 != 5'h0) ? x[ra2] : 32'h0;

endmodule
