module CHECK_CLK #(FREQ = 50000000)(
	input clk,reset,
	output reg LEDR
);

reg [31:0] cnt;

always @(posedge clk, posedge reset)
	if(reset)
		{LEDR, cnt} <= 33'h0;
	else begin
		cnt <= cnt + 1'b1;
		if(cnt == FREQ) begin
			LEDR <= ~LEDR;
			cnt <= 32'h0;
		end
	end

endmodule

