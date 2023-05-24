//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module jpeg_qnr_wrap_noc_big(clk, ena, rst, packed_in, packed_out);

	//
	// parameters
	//
	parameter PARALLEL = 39;

	//
	// inputs & outputs
	//
	input clk;                    // system clock
	input ena;                    // clock enable
	input rst;                    // asynchronous active low reset

	input [12:0] packed_in  [0:PARALLEL-1];
	
	output reg [12:0] packed_out [0:PARALLEL-1];


//---------------------------------------------------
// Implementation
//---------------------------------------------------


generate

genvar i;

for (i=0; i<PARALLEL; i++)
begin:dcts
	// Hookup quantizers
	jpeg_qnr_wrap_noc
	qnr(
		.clk(clk),
		.rst(rst),
		.ena(1'b1),
	
		.packed_in(packed_in[i]),
		.packed_out(packed_out[i])
);


end

endgenerate

endmodule
