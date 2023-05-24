//synopsys translate_off
`include "timescale.v"
//synopsys translate_on

module jpeg_rle_noc_big(clk, rst, ena, packed_in, size, rlen, amp, douten, bstart);

	//
	// parameters
	//
	
	parameter PARALLEL = 39;

	//
	// inputs & outputs
	//
	input         clk;     // system clock
	input         rst;     // asynchronous reset
	input         ena;     // clock enable
	
	input [12:0]  packed_in [0:PARALLEL-1];

	output [ 3:0] size   [0:PARALLEL-1];  // size
	output [ 3:0] rlen   [0:PARALLEL-1];  // run-length
	output [11:0] amp    [0:PARALLEL-1];  // amplitude
	output        douten [0:PARALLEL-1];  // data output enable
	output        bstart [0:PARALLEL-1];  // block start


//---------------------------------------------------
// Implementation
//---------------------------------------------------


generate

genvar i;

for (i=0; i<PARALLEL; i++)
begin:dcts
	// Hookup encoders
	jpeg_rle_noc
	rle(
		.clk(clk),
		.rst(rst),
		.ena(1'b1),
		
		.packed_in(packed_in[i]),
		
		.size(size[i]),
		.rlen(rlen[i]),
		.amp(amp[i]),
		.douten(douten[i]),
		.bstart(bstart[i])
	);

end

endgenerate

endmodule
