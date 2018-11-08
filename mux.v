module MUX2	#(parameter WIDTH = 32)(
	input [WIDTH-1:0]	d0, d1,
	input s,
	output [WIDTH-1:0] y
);

assign y = s ? d1 : d0;

endmodule


module MUX4	#(parameter WIDTH = 32)
(
	input [WIDTH-1:0]	d0, d1, d2, d3,
	input [1:0] s,
	output reg [WIDTH-1:0] y
);

always @*
	case(s)
		2'b00: y <= d0;
		2'b01: y <= d1;
		2'b10: y <= d2;
		2'b11: y <= d3;
		default: y <= 0;
	endcase


endmodule


module MUX8	#(parameter WIDTH = 32)
(
	input [WIDTH-1:0]	d0, d1, d2, d3, d4, d5, d6, d7,
	input [2:0] s,
	output reg [WIDTH-1:0] y
);

always @*
	case(s)
		3'h0: y = d0;
		3'h1: y = d1;
		3'h2: y = d2;
		3'h3: y = d3;
		3'h4: y = d4;
		3'h5: y = d5;
		3'h6: y = d6;
		3'h7: y = d7;
		default: y = 0;
	endcase


endmodule
