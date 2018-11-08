module EDGE_TO_PULSE #(parameter DATA_WIDTH = 1, parameter EDGE_TYPE = 1)
(
	input clk,
	input [DATA_WIDTH - 1:0] din,
	output [DATA_WIDTH - 1:0] dout
);

// EDGE_TYPE ==  0 : negative-edge (1->0), 1 : positive-edge (0->1)

reg  [DATA_WIDTH - 1:0]   prev_din2;
wire [DATA_WIDTH - 1:0]   din2 = (EDGE_TYPE == 1) ? din : ~din;
always @ (posedge clk) 
	prev_din2 <= din2;

assign dout = ~prev_din2 & din2;

endmodule
