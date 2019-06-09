module SEG7DEC #(POINT = 0) (
	input [3:0] num,
	output reg [7:0] nHEX
);

always @* begin
	nHEX[7] <= POINT ? 1'b0 : 1'b1;
	case(num)
		4'h0 : nHEX[6:0] = 7'b1000000;
		4'h1 : nHEX[6:0] = 7'b1111001;
		4'h2 : nHEX[6:0] = 7'b0100100;
		4'h3 : nHEX[6:0] = 7'b0110000;
		4'h4 : nHEX[6:0] = 7'b0011001;
		4'h5 : nHEX[6:0] = 7'b0010010;
		4'h6 : nHEX[6:0] = 7'b0000010;
		4'h7 : nHEX[6:0] = 7'b1111000;
		4'h8 : nHEX[6:0] = 7'b0000000;
		4'h9 : nHEX[6:0] = 7'b0010000;
		4'ha : nHEX[6:0] = 7'b0001000;
		4'hb : nHEX[6:0] = 7'b0000011;
		4'hc : nHEX[6:0] = 7'b0100111;
		4'hd : nHEX[6:0] = 7'b0100001;
		4'he : nHEX[6:0] = 7'b0000100;
		4'hf : nHEX[6:0] = 7'b0001110;
		default:nHEX[6:0] = 7'b0110110;
	endcase
end

endmodule

